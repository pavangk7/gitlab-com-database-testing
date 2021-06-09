# frozen_string_literal: true

require 'pg_query'

class Query
  QUERY_GUIDANCE_MILLISECONDS = 100
  TIMING_GUIDELINES = 'https://docs.gitlab.com/ee/development/query_performance.html#timing-guidelines-for-queries'

  # rubocop:disable Layout/LineLength
  EXCLUSIONS = [
    "select pg_database_size(current_database()) /*application:test*/",
    "SELECT \"schema_migrations\".\"version\" FROM \"schema_migrations\" ORDER BY \"schema_migrations\".\"version\" ASC /*application:test*/",
    "select pg_stat_statements_reset() /*application:test*/",
    "SELECT c.relname FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = ANY (current_schemas($1)) AND c.relname = $2 AND c.relkind IN ($3,$4)",
    "INSERT INTO \"schema_migrations\" (\"version\") VALUES ($1) RETURNING \"version\" /*application:test*/",
    "SELECT \"ar_internal_metadata\".* FROM \"ar_internal_metadata\" WHERE \"ar_internal_metadata\".\"key\" = $1 LIMIT $2 /*application:test*/",
    "SELECT pg_try_advisory_lock($1)",
    "SELECT pg_advisory_unlock($1)",
    "SELECT current_database()",
    "SELECT $1",
    "SELECT current_schema"
  ].map(&:downcase).freeze
  # rubocop:enable Layout/LineLength

  attr_accessor :query, :calls, :total_time, :max_time, :mean_time, :rows

  def initialize(pgss_row)
    @query = pgss_row['query']
    @calls = pgss_row['calls']
    @total_time = pgss_row['total_time']
    @max_time = pgss_row['max_time']
    @mean_time = pgss_row['mean_time']
    @rows = pgss_row['rows']
  end

  def formatted_query
    Niceql::Prettifier.prettify_sql(query)
      .gsub(' ', '&nbsp;')
      .gsub('/*', '&#x2F;&#x2A;')
      .gsub('*/', '&#x2A;&#x2F;')
      .gsub("\n", '<br />')
  rescue StandardError => e
    warn "Query formatting error:\n#{e}\nFor query: #{query}"
    query
  end

  def exceeds_time_guidance?
    max_time > QUERY_GUIDANCE_MILLISECONDS
  end

  def timing
    if calls == 1
      "it was #{max_time}"
    else
      "the longest was #{max_time}ms, and the average was #{mean_time}ms"
    end
  end

  def warning(migration_name)
    "#{migration_name} had a query that [exceeded timing guidelines](#{TIMING_GUIDELINES}). Run time "\
    "should not exceed 100ms, but #{timing} <pre>#{formatted_query}</pre>"
  end

  def excluded?
    return true if query.downcase.start_with?(/commit|show|reset|begin|release savepoint|savepoint|set|rollback/)
    return true if query.include?('/* pgssignore */')
    return true if EXCLUSIONS.include?(query.downcase)

    tables = PgQuery.parse(query).tables

    return false if tables.empty?

    return true if tables.all? { |table| table.start_with?('pg_') }
    return true if tables.uniq == ['ar_internal_metadata']

    false
  rescue PgQuery::ParseError => e
    warn "Query parse error:\n#{e}\nFor query: #{query}"
    false
  end
end
