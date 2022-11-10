# frozen_string_literal: true

class MigrationLister
  MIGRATION_VERSION_REGEX = %r{^db/(post_)?migrate/(\d+)}.freeze
  MIGRATION_NAME_REGEX = /class (\w+) < (?:ActiveRecord::Migration|Gitlab::Database::Migration)/.freeze
  ADDED_FILE_REGEX = /\AA\t/.freeze
  MIGRATION_FOLDERS = ['db/migrate', 'db/post_migrate'].freeze

  class NonExistentFolderError < StandardError; end
  class GitError < StandardError; end

  def initialize
    MIGRATION_FOLDERS.each do |folder|
      raise NonExistentFolderError, "#{folder} is not present" unless File.directory?(folder)
    end
  end

  def migrations
    new_migrations = build_hash(read_new_migrations)
    all_migrations = build_hash(read_all_migrations)

    all_migrations.each do |version, migration|
      migration[:intro_on_current_branch] = !new_migrations[version].nil?
    end
  end

  private

  def build_hash(migrations)
    migrations.each_with_object({}) do |f, h|
      migration = migration_details(f)
      h[migration[:version]] = migration
    end
  end

  def migration_details(filename)
    {
      version: migration_version(filename),
      path: filename,
      name: migration_name(filename),
      type: migration_type(filename)
    }
  end

  def migration_type(filename)
    filename.start_with?('db/post_migrate') ? :post_deploy : :regular
  end

  def migration_version(filename)
    filename.match(MIGRATION_VERSION_REGEX) { |m| m.captures[1]&.to_i }
  end

  def migration_name(filename)
    File.read(filename).match(MIGRATION_NAME_REGEX) { |m| m.captures[0] }
  end

  def read_all_migrations
    MIGRATION_FOLDERS.inject([]) { |files, dir| files.concat(Dir.glob("#{dir}/*.rb")) }
  end

  def read_new_migrations
    read_from_git.split("\n").select { |l| l =~ ADDED_FILE_REGEX }.map { |l| l.split("\t").last }
  end

  def read_from_git
    results = `git diff --name-status origin/master...HEAD #{MIGRATION_FOLDERS.join(' ')}`
    raise GitError, "Error invoking git: #{results}" if $?.exitstatus != 0

    results
  end
end
