# frozen_string_literal: true

require 'pg_query'
require_relative 'query_execution'
require_relative 'query_exclusion'

class Query
  QUERY_GUIDANCE_MILLISECONDS = 100
  CONCURRENT_QUERY_GUIDANCE_MILLISECONDS = 5.minutes.in_milliseconds
  TIMING_GUIDELINES = 'https://docs.gitlab.com/ee/development/query_performance.html#timing-guidelines-for-queries'

  attr_accessor :query, :calls, :total_time, :max_time, :mean_time, :rows, :executions

  def initialize(pgss_row)
    @query = PgQuery.normalize(pgss_row['query'])
    @calls = pgss_row['calls']
    @total_time = pgss_row['total_time']
    @max_time = pgss_row['max_time']
    @mean_time = pgss_row['mean_time']
    @rows = pgss_row['rows']
  end

  def formatted_query
    Niceql::Prettifier.prettify_sql(query)
      .gsub('/*', '&#x2F;&#x2A;')
      .gsub('*/', '&#x2A;&#x2F;')
      .gsub("\n", '<br />')
      .gsub('|', '&#124;')
  rescue StandardError => e
    warn "Query formatting error:\n#{e}\nFor query: #{query}"
    query
  end

  def concurrent?
    query.downcase.include?('create index concurrently')
  end

  def time_guidance
    return CONCURRENT_QUERY_GUIDANCE_MILLISECONDS if concurrent?

    QUERY_GUIDANCE_MILLISECONDS
  end

  def exceeds_time_guidance?
    max_time > time_guidance
  end

  def timing
    if calls == 1
      "it was #{max_time.truncate(2)}"
    else
      "the longest was #{max_time.truncate(2)}ms, and the average was #{mean_time.truncate(2)}ms"
    end
  end

  def warning(migration_name)
    "#{migration_name} had a query that [exceeded timing guidelines](#{TIMING_GUIDELINES}). Run time "\
    "should not exceed #{time_guidance}ms, but was #{timing}ms. Please consider possible options to "\
    "improve the query performance. <br/><pre>#{formatted_query}</pre>"
  end

  def excluded?
    QueryExclusion.exclude?(query)
  end
end
