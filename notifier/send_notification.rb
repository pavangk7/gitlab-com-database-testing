#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'json'
require 'pry'
require 'filesize'

gitlab = Gitlab.client(
  endpoint: 'https://gitlab.com/api/v4',
  private_token: ENV['GITLAB_API_TOKEN']
)

project_path = ENV['TOP_UPSTREAM_SOURCE_PROJECT']
merge_request_id = ENV['TOP_UPSTREAM_MERGE_REQUEST_IID']

stats_file = ARGV[0]

UNKNOWN = ':grey_question:'.freeze

def total_size_change(migration)
  size_change_bytes = migration['total_database_size_change']

  return UNKNOWN unless size_change_bytes
  sign = (size_change_bytes < 0) ? '-' : '+'
  size_change = Filesize.from("#{size_change_bytes.abs} B").pretty

  sign + size_change
end

def success(migration)
  return UNKNOWN unless migration['success']

  (migration['success']) ? ":white_check_mark:" : ":boom:"
end

def walltime(migration)
  return UNKNOWN unless migration['walltime']

  "#{migration['walltime'].round(1)}s"
end

def pgss_table(migration)
  return '' unless migration['query_statistics']

  table = migration['query_statistics'].map do |stat|
    inner = %w(query calls total_time max_time mean_time rows).map { |key| stat[key] }.join('|')

    '|' + inner + '|'
  end

  <<~TABLE
    | Query | Calls | Total Time | Max Time | Mean Time | Rows |
    | ----- | ----- | ---------- | -------- | --------- | ---- |
    #{table.join("\n")}
  TABLE
end

def migration_details(migration)
  <<~COMMENT
    ##### Migration: #{migration['migration']}

    #{pgss_table(migration)}
  COMMENT
end

begin
  stats = JSON.parse(File.read(stats_file))

  migrations_table = stats.map do |migration|
    "| #{migration['migration']} | #{walltime(migration)} | #{success(migration)} | #{total_size_change(migration)}"
  end

  migration_details = stats.map do |migration|
    migration_details(migration)
  end

  comment = <<~COMMENT
    ### Database migrations
    Migrations included in this change have been executed on gitlab.com data for testing purposes.

    | Migration | Total runtime | Result | DB size change |
    | --------- | ------------- | ------ | -------------- |
    #{migrations_table.join("\n")}

    #{migration_details.join("\n")}

    For details, please see the [migration testing pipeline](#{ENV['CI_PROJECT_URL']}/-/pipelines/#{ENV['CI_PIPELINE_ID']}) (limited access).

    ---
    Brought to you by [gitlab-org/database-team/gitlab-com-database-testing](https://gitlab.com/gitlab-org/database-team/gitlab-com-database-testing).
  COMMENT

  puts comment

  raise "Project path missing: Specify TOP_UPSTREAM_SOURCE_PROJECT" unless project_path
  raise "Upstream merge request id missing: Specify TOP_UPSTREAM_MERGE_REQUEST_IID" unless merge_request_id

  gitlab.create_merge_request_discussion(project_path, merge_request_id, body: comment)
rescue Gitlab::Error::Error => e
  puts "Ignoring the following error: #{e}"
rescue => e
  puts "Ignoring the following error: #{e}"
end
