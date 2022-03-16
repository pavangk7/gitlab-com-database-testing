# frozen_string_literal: true

require 'ostruct'
require 'json'

class Result
  def self.from_directory(database_testing_path)
    statistics_file = File.join(database_testing_path, 'up', 'migration-stats.json')
    migrations_file = File.join(database_testing_path, 'migrations.json')
    clone_details_file = File.join(database_testing_path, 'clone-details.json')
    query_details_path = File.join(database_testing_path, 'up')

    stats = read_to_json(statistics_file).each_with_object({}) do |stat, h|
      version = stat['version']
      h[version] = stat
    end

    # Attach statistics to each migration
    migrations = read_to_json(migrations_file).each_with_object({}) do |(version, migration), h|
      version = version.to_i
      name = migration['name']

      details_path = if schema_version(database_testing_path) > 1
                       File.join(query_details_path, name, 'query-details.json')
                     else
                       File.join(query_details_path, "#{version}_#{name}-query-details.json")
                     end

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

  def sorted_migrations
    migrations.values.sort_by(&:sort_key)
  end

  def self.read_to_json(path)
    JSON.parse(File.read(path))
  end

  def self.schema_version(path)
    metadata_file = File.join(path, 'up', 'metadata.json')

    if File.exist?(metadata_file)
      read_to_json(metadata_file)['version']
    else
      1
    end
  end
end
