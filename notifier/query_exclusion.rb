# frozen_string_literal: true

require 'pg_query'

class QueryExclusion
  # rubocop:disable Layout/LineLength
  EXCLUSIONS = [
    "select pg_database_size(current_database())",
    "SELECT \"schema_migrations\".\"version\" FROM \"schema_migrations\" ORDER BY \"schema_migrations\".\"version\" ASC",
    "select pg_stat_statements_reset()",
    "SELECT c.relname FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = ANY (current_schemas($1)) AND c.relname = $2 AND c.relkind IN ($3,$4)",
    "INSERT INTO \"schema_migrations\" (\"version\") VALUES ($1) RETURNING \"version\"",
    "SELECT \"ar_internal_metadata\".* FROM \"ar_internal_metadata\" WHERE \"ar_internal_metadata\".\"key\" = $1 LIMIT $2",
    "SELECT pg_try_advisory_lock($1)",
    "SELECT pg_advisory_unlock($1)",
    "SELECT current_database()",
    "SELECT $1",
    "SELECT current_schema",
    "SELECT \"postgres_async_indexes\".* FROM \"postgres_async_indexes\" WHERE \"postgres_async_indexes\".\"name\" = $1 LIMIT $2"
  ].map { |q| PgQuery.parse(q).deparse.downcase }.freeze
  # rubocop:enable Layout/LineLength

  def self.exclude?(sql)
    normalized_query = PgQuery.normalize(sql).downcase
    return true if normalized_query.include?('/* pgssignore */')

    query_without_comments = PgQuery.parse(normalized_query).deparse.downcase
    return true if query_without_comments.start_with?(/commit|show|reset|begin|release|savepoint|set|rollback/)
    return true if EXCLUSIONS.include?(query_without_comments)

    tables = PgQuery.parse(query_without_comments).tables

    return false if tables.empty?

    return true if tables.all? { |table| table.start_with?('pg_') }
    return true if tables.uniq == ['ar_internal_metadata']

    false
  rescue PgQuery::ParseError => e
    warn "Query parse error:\n#{e}\nFor query: #{sql}"
    false
  end
end
