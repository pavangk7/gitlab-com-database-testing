# frozen_string_literal: true

require 'ostruct'
require 'json'

class Result
  def self.from_directory(database_testing_path)
    migrations_file = File.join(database_testing_path, 'migrations.json')
    clone_details_file = File.join(database_testing_path, 'clone-details.json')
    query_details_path = File.join(database_testing_path, 'up')

    stats = read_stats(query_details_path)

    # Attach statistics to each migration
    migrations = read_to_json(migrations_file).each_with_object({}) do |(version, migration), h|
      version = version.to_i
      name = migration['name']

      details_path = File.join(query_details_path, name, 'query-details.json')

      query_details = if File.exist?(details_path)
                        read_to_json(details_path)
                      else
                        []
                      end

      h[version] = Migration.new(migration, stats[version], query_details)
    end

    # Attach clone details
    clone_details = OpenStruct.new(JSON.parse(File.read(clone_details_file)))

    # Migrations with statistics have been executed in this run, others not
    # Limit to executed migrations
    migrations = migrations.select do |_, migration|
      migration.was_run?
    end

    Result.new(migrations, clone_details)
  end

  attr_reader :migrations, :clone_details

  def initialize(migrations, clone_details)
    @migrations = migrations
    @clone_details = clone_details
  end

  def migrations_from_branch
    sorted_migrations.select(&:intro_on_current_branch?)
  end

  def other_migrations
    sorted_migrations.reject(&:intro_on_current_branch)
  end

  private

  def self.read_stats_legacy(stats_file)
    read_to_json(stats_file).index_by { |s| s['version'] }
  end

  def self.read_stats(migration_dir_path)
    Pathname(migration_dir_path).children
                                .select(&:directory?)
                                .map { |dir| read_to_json(dir.join('migration-stats.json')) }
                                .index_by { |s| s['version'] }
  end

  def sorted_migrations
    migrations.values.sort_by(&:sort_key)
  end

  def self.read_to_json(path)
    JSON.parse(File.read(path))
  end

  def self.schema_version(path)
    metadata_file = File.join(path, 'up', 'metadata.json')

    read_to_json(metadata_file)['version']
  end
end
