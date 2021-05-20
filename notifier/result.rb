# frozen_string_literal: true

require 'ostruct'

class Result
  def self.from_files(statistics_file, migrations_file)
    stats = JSON.parse(File.read(statistics_file)).each_with_object({}) do |stat, h|
      version = stat['migration']
      h[version] = stat
    end

    # Attach statistics to each migration
    migrations = JSON.parse(File.read(migrations_file)).each_with_object({}) do |(version, migration), h|
      version = version.to_i

      migration['statistics'] = stats[version]
      h[version] = to_recursive_ostruct(migration)
    end

    # Migrations with statistics have been executed in this run, others not
    # Limit to executed migrations
    migrations = migrations.select do |_, migration|
      !migration['statistics'].nil?
    end

    Result.new(migrations)
  end

  attr_reader :migrations

  def initialize(migrations)
    @migrations = migrations
  end

  def self.to_recursive_ostruct(hash)
    OpenStruct.new(hash.transform_values do |val|
      val.is_a?(Hash) ? to_recursive_ostruct(val) : val
    end)
  end

  private_class_method :to_recursive_ostruct
end
