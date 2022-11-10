# frozen_string_literal: true

require 'pg_query'
require_relative 'query_execution'
require_relative 'query_exclusion'

class Query
  QUERY_GUIDANCE_MILLISECONDS = 100
  CONCURRENT_QUERY_GUIDANCE_MILLISECONDS = 5.minutes.in_milliseconds
  TIMING_GUIDELINES = 'https://docs.gitlab.com/ee/development/query_performance.html#timing-guidelines-for-queries'
  CREATE_TABLE_STATMENT ='create table'

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
    Niceql::Prettifier.prettify_sql(query, false)
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

  def new_table_fields_and_types
    return unless new_table?

    result = []

    PgQuery.parse(query).tree.stmts.first.stmt.create_stmt.table_elts.each do |elt|
      elt.column_def.type_name.names.each do |part|
        column_name = elt.column_def.colname
        data_type = part.string.str

        next if data_type == 'pg_catalog'

        result << [column_name, data_type]
      end
    end

    result
  end

  def time_guidance
    return CONCURRENT_QUERY_GUIDANCE_MILLISECONDS if concurrent?

    QUERY_GUIDANCE_MILLISECONDS
  end

  def exceeds_time_guidance?
    max_time > time_guidance
  end

  def timing_phrase
    if calls == 1
      "it was #{max_time.truncate(2)}ms"
    else
      "the longest was #{max_time.truncate(2)}ms, and the average was #{mean_time.truncate(2)}ms"
    end
  end

  def warning(migration_name)
    "#{migration_name} had a query that [exceeded timing guidelines](#{TIMING_GUIDELINES}). Run time "\
    "should not exceed #{time_guidance}ms, but #{timing_phrase}. Please consider possible options to "\
    "improve the query performance. <br/><pre>#{formatted_query}</pre>"
  end

  def excluded?
    QueryExclusion.exclude?(query)
  end

  private

  def new_table?
    query.downcase.include?(CREATE_TABLE_STATMENT)
  end
end
