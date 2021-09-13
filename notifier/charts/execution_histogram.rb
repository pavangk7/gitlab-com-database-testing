# frozen_string_literal: true

module Charts
  class ExecutionHistogram
    DEFAULT_CUTOFFS = [
      0.01.seconds,
      0.1.seconds,
      1.second,
      5.minutes
    ].freeze

    attr_reader :query_executions, :buckets, :title

    def self.for_result(result)
      executions = result.migrations_from_branch
                         .flat_map(&:important_query_executions)
      new(executions, title: 'Runtime Histogram for all migrations')
    end

    def self.for_migration(migration)
      new(migration.important_query_executions, title: "Histogram for #{migration.name}")
    end

    def initialize(query_executions, title:, bucket_cutoffs: DEFAULT_CUTOFFS)
      @query_executions = query_executions
      @title = title
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

    def render
      return '' if query_executions.empty?

      ERB.new(File.read('templates/charts/histogram.erb'), trim_mode: '-').result(binding)
    end
  end
end
