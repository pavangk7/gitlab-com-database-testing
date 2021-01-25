#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'json'
require 'pry'

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
    "| #{migration['version']} | #{migration['walltime'].round(1)}s |"
  end

  comment = <<~COMMENT
    ### Database migrations
    Migrations included in this change have been executed on gitlab.com data for testing purposes.

    | Migration | Total runtime |
    | --------- | ------------- |
    #{migrations_table.join("\n")}

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
