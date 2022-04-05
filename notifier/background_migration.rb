# frozen_string_literal: true

class BackgroundMigration
  def self.from_directory(directory)
    name = directory.basename
    batches = directory.children.select(&:directory?)
                       .map { |d| Migration.background_migration_batch_from_directory(d) }

    new(name, batches)
  end

  attr_reader :name, :batches

  def initialize(name, batches)
    @name = name
    @batches = batches
  end

  def queries
    matching_queries = batches.flat_map(&:queries).group_by(&:query)

    matching_queries.map do |query_text, queries|
      # Each query here comes from pg_stat_statements, so it has already been aggregated for a single batch
      # Aggregate again to get a view of what pg_stat_statements might look like if all batches were run
      # without clearing it.

      calls = queries.sum(&:calls)
      total_time = queries.sum(&:total_time)
      max_time = queries.map(&:max_time).max
      mean_time = queries.sum { |q| q.mean_time * q.calls } / calls
      rows = queries.sum(&:rows)
      query_data = {
        query: query_text,
        calls: calls,
        total_time: total_time,
        max_time: max_time,
        mean_time: mean_time,
        rows: rows
      }.stringify_keys
      Query.new(query_data)
    end
  end
end
