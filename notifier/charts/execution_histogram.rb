# frozen_string_literal: true

module Charts
  class ExecutionHistogram
    DEFAULT_CUTOFFS = [
      0.01.seconds,
      0.1.seconds,
      1.second,
      5.minutes
    ].freeze

    # Background migration queries can take up to 1 second
    # We don't need a large bucket for concurrent index creation
    # because that won't happen in a background migration
    BACKGROUND_MIGRATION_QUERY_CUTOFFS = [
      0.1.seconds,
      0.5.seconds,
      1.second,
      2.seconds,
      5.seconds
    ].freeze

    BACKGROUND_MIGRATION_BATCH_CUTOFFS = [
      10.seconds,
      1.minute,
      2.minutes,
      3.minutes,
      5.minutes
    ].freeze

    PLACEHOLDER_TEMPLATE = 'templates/charts/placeholder.erb'

    HISTOGRAM_TEMPLATE = 'templates/charts/histogram.erb'

    attr_reader :query_executions, :buckets, :title, :column_label

    def self.for_result(result)
      executions = result.migrations_from_branch
                         .flat_map(&:important_query_executions)
      new(executions, title: 'Runtime Histogram for all migrations', column_label: 'Query Runtime')
    end

    def self.for_migration(migration)
      new(migration.important_query_executions, title: "Histogram for #{migration.name}", column_label: 'Query Runtime')
    end

    def self.for_background_migration_queries(background_migration)
      queries = background_migration.batches.flat_map(&:important_query_executions)
      new(queries,
          title: "Histogram across all sampled batches of #{background_migration.name}",
          column_label: 'Query Runtime',
          bucket_cutoffs: BACKGROUND_MIGRATION_QUERY_CUTOFFS)
    end

    def self.for_background_migration_batches(background_migration)
      new(background_migration.batches,
          title: "Histogram of batch runtimes for #{background_migration.name}",
          column_label: 'Batch Runtime',
          bucket_cutoffs: BACKGROUND_MIGRATION_BATCH_CUTOFFS)
    end

    def initialize(query_executions, title:, column_label:, bucket_cutoffs: DEFAULT_CUTOFFS)
      @query_executions = query_executions
      @title = title
      @column_label = column_label
      @buckets = ([0.seconds] + bucket_cutoffs)
                   .zip(bucket_cutoffs + [nil])
                   .map { |(lo, hi)| lo..hi }
    end

    def bucket_for(execution)
      buckets.find do |b|
        b.include?(execution.duration)
      end
    end

    def data
      @query_executions.each_with_object(buckets.to_h { |b| [b, []] }) { |e, buckets| buckets[bucket_for(e)] << e }
    end

    def bucket_label(bucket)
      if bucket.begin && bucket.end
        "#{bucket.begin.inspect} - #{bucket.end.inspect}"
      else
        "#{bucket.begin.inspect} +"
      end
    end

    def template
      return PLACEHOLDER_TEMPLATE if query_executions.empty?

      HISTOGRAM_TEMPLATE
    end

    def render
      ERB.new(File.read(template), trim_mode: '-').result(binding)
    end
  end
end
