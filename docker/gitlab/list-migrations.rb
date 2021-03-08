#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'json'

def extract_migration_details(file)
  version = file.match(/^db\/(post_)?migrate\/(\d+)/) { |m| m.captures[1]&.to_i }
  name = File.read(file).match(/class (\w+) \< ActiveRecord::Migration/) { |m| m.captures[0] }
  type = (file.start_with?('db/post_migrate')) ? :post_deploy : :regular

  {
    version: version,
    path: file,
    name: name,
    type: type
  }
end

def build_hash(files)
  files.map do |f|
    extract_migration_details(f)
  end.each_with_object({}) do |migration, h|
    h[migration[:version]] = migration
  end
end

migrations_on_this_branch = build_hash(`git diff --name-only origin/master...HEAD db/post_migrate db/migrate`.split("\n"))
all_migrations = build_hash(Dir.glob("db/{post_migrate,migrate}/*.rb"))

all_migrations.each do |version, migration|
  migration[:intro_on_current_branch] = !migrations_on_this_branch[version].nil?
end

puts all_migrations.to_json
