#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'json'
require 'pry'
require 'thor'

require_relative 'feedback'

class Notifier < Thor
  desc "send FILE", "send feedback back to merge request"
  def send(file)

    project_path = ENV['TOP_UPSTREAM_SOURCE_PROJECT']
    merge_request_id = ENV['TOP_UPSTREAM_MERGE_REQUEST_IID']

    raise "Project path missing: Specify TOP_UPSTREAM_SOURCE_PROJECT" unless project_path
    raise "Upstream merge request id missing: Specify TOP_UPSTREAM_MERGE_REQUEST_IID" unless merge_request_id


    stats = JSON.parse(File.read(file))
    comment = Feedback.new(stats).render

    gitlab = Gitlab.client(
      endpoint: 'https://gitlab.com/api/v4',
      private_token: ENV['GITLAB_API_TOKEN']
    )

    gitlab.create_merge_request_discussion(project_path, merge_request_id, body: comment)
  rescue Gitlab::Error::Error => e
    puts "Ignoring the following error: #{e}"
  rescue => e
    puts "Ignoring the following error: #{e}"
  end

  desc "print FILE", "only print feedback"
  def print(file)
    stats = JSON.parse(File.read(file))

    puts Feedback.new(stats).render
  end
end

Notifier.start(ARGV)
