#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'json'
require 'pry'
require 'thor'

require_relative 'feedback'
require_relative 'result'

IDENTIFIABLE_NOTE_TAG = 'gitlab-org/database-team/gitlab-com-database-testing:identifiable-note'

class Notifier < Thor
  desc "send STATS MIGRATIONS", "send feedback back to merge request"
  def send(statistics_file, migrations_file)
    project_path = ENV['TOP_UPSTREAM_SOURCE_PROJECT']
    merge_request_id = ENV['TOP_UPSTREAM_MERGE_REQUEST_IID']

    raise "Project path missing: Specify TOP_UPSTREAM_SOURCE_PROJECT" unless project_path
    raise "Upstream merge request id missing: Specify TOP_UPSTREAM_MERGE_REQUEST_IID" unless merge_request_id

    comment = feedback_for(statistics_file, migrations_file).render

    gitlab = Gitlab.client(
      endpoint: 'https://gitlab.com/api/v4',
      private_token: ENV['GITLAB_API_TOKEN']
    )

    ignore_errors do # adding the label is optional
      gitlab.update_merge_request(project_path, merge_request_id, add_labels: ['database-testing-automation'])
    end

    # Look for a note to update
    db_testing_notes = gitlab.merge_request_notes(project_path, merge_request_id).auto_paginate.select do |note|
      note.body.include?(IDENTIFIABLE_NOTE_TAG)
    end

    note = db_testing_notes.max_by { |note| Time.parse(note.created_at) }

    if note && note.type != 'DiscussionNote'
      # The latest note has not led to a discussion. Update it.
      gitlab.edit_merge_request_note(project_path, merge_request_id, note.id, comment)

      puts "Updated comment:\n"
    else
      # This is the first note or the latest note has been discussed on the MR.
      # Don't update, create new note instead.
      note = gitlab.create_merge_request_note(project_path, merge_request_id, comment)

      puts "Posted comment to:\n"
    end

    puts "https://gitlab.com/#{project_path}/-/merge_requests/#{merge_request_id}#note_#{note.id}"
  end

  desc "print STATS MIGRATIONS", "only print feedback"
  def print(statistics_file, migrations_file)
    puts feedback_for(statistics_file, migrations_file).render
  end

  private

  def feedback_for(statistics_file, migrations_file)
    result = Result.from_files(statistics_file, migrations_file)

    Feedback.new(result)
  end

  def ignore_errors
    yield
  rescue Gitlab::Error::Error => e
    puts "Ignoring the following error: #{e}"
  rescue StandardError => e
    puts "Ignoring the following error: #{e}"
  end
end

Notifier.start(ARGV)
