# frozen_string_literal: true

require 'pg_query'

class QueryExclusion
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

  def self.exclude?(sql)
    normalized_query = PgQuery.normalize(sql).downcase
    return true if normalized_query.start_with?(/commit|show|reset|begin|release savepoint|savepoint|set|rollback/)
    return true if normalized_query.include?('/* pgssignore */')
    return true if EXCLUSIONS.include?(normalized_query)

    tables = PgQuery.parse(normalized_query).tables

    return false if tables.empty?

    return true if tables.all? { |table| table.start_with?('pg_') }
    return true if tables.uniq == ['ar_internal_metadata']

    false
  rescue PgQuery::ParseError => e
    warn "Query parse error:\n#{e}\nFor query: #{query}"
    false
  end
end