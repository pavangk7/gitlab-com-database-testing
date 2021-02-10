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

begin
  stats = JSON.parse(File.read(stats_file))

  migrations_table = stats.map do |migration|
    result = (migration['success']) ? ":white_check_mark:" : ":boom:"
    sign = (migration['total_database_size_change'] < 0) ? '-' : '+'
    size_change = Filesize.from("#{migration['total_database_size_change'].abs} B").pretty
    "| #{migration['migration']} | #{migration['walltime'].round(1)}s | #{result} | #{sign}#{size_change}"
  end

  comment = <<~COMMENT
    ### Database migrations
    Migrations included in this change have been executed on gitlab.com data for testing purposes.

    | Migration | Total runtime | Result | DB size change |
    | --------- | ------------- | ------ | -------------- |
    #{migrations_table.join("\n")}

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
