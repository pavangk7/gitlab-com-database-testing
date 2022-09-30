# frozen_string_literal: true

class MultiDbResult
  def self.from_directory(database_testing_path)
    migrations_file = File.join(database_testing_path, 'migrations.json')
    clone_details_file = File.join(database_testing_path, 'clone-details.json')

    global_migration_data = read_to_json(migrations_file)

    clone_details = read_clone_details(clone_details_file)

    per_db_results = per_database_path_parts(database_testing_path).transform_values do |path|
      Result.from_directory(path, global_migration_data, clone_details)
    end

    MultiDbResult.new(per_db_results)
  end

  attr_reader :per_db_results

  def initialize(per_db_results)
    @per_db_results = per_db_results
  end

  private

  def self.per_database_path_parts(database_testing_path)
    metadata_files = Dir.glob(File.join(database_testing_path, '**/up/metadata.json'))
    metadata_files.to_h do |f|
      data = JSON.parse(File.read(f))
      # We strip two layers off with .dirname.dirname to remove the /up/metadata.json component
      if data['version'] == 3
        ['main', Pathname(f).dirname.dirname.to_s] # version 3 is implicitly main
      else
        [data['database'], Pathname(f).dirname.dirname.to_s]
      end
    end
  end

  def self.read_clone_details(details_filename)
    JSON.parse(File.read(details_filename)).map do |detail|
      OpenStruct.new(detail)
    end
  end


  def self.read_to_json(path)
    JSON.parse(File.read(path))
  end

end
