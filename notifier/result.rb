# frozen_string_literal: true

require 'ostruct'
require 'json'

class Result
  def self.from_directory(database_testing_path, global_migration_data, clone_details)

    query_details_path = File.join(database_testing_path, 'up')

    background_migrations_path = File.join(database_testing_path, 'background_migrations')

    migrations = Pathname(query_details_path)
                   .children
                   .select(&:directory?)
                   .map { |d| Migration.from_directory(d, global_migration_data: global_migration_data) }
                   .index_by(&:version)

    background_migrations = Pathname(background_migrations_path)
                              .children.select(&:directory?)
                              .map { |d| BackgroundMigration.from_directory(d) }

    # Migrations with statistics have been executed in this run, others not
    # Limit to executed migrations
    migrations = migrations.select do |_, migration|
      migration.was_run?
    end

    database = metadata(database_testing_path)['database'] || 'main'

    Result.new(migrations, background_migrations, clone_details, database)
  end

  attr_reader :migrations, :background_migrations, :clone_details, :database

  def initialize(migrations, background_migrations, clone_details, database)
    @migrations = migrations
    @background_migrations = background_migrations
    @clone_details = clone_details
    @database = database
  end

  def migrations_from_branch
    sorted_migrations.select(&:intro_on_current_branch?)
  end

  def other_migrations
    sorted_migrations.reject(&:intro_on_current_branch)
  end



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
    metadata(path)['version']
  end

  def self.metadata(path)
    metadata_file = File.join(path, 'up', 'metadata.json')

    read_to_json(metadata_file)
  end
end
