require 'filesize'
require 'erb'
require_relative 'niceql'
require 'pg_query'

class Feedback
  UNKNOWN = ':grey_question:'.freeze

  attr_reader :result

  def initialize(result)
    @result = result
  end

  def render
    erb('feedback').result(binding)
  end

  private

  def migrations_from_branch
    all_migrations.select do |migration|
      migration.intro_on_current_branch
    end
  end

  def all_migrations
    result.migrations.values
  end

  def render_details(migration)
    erb('detail').result(binding)
  end

  def render_pgss_table(pgss)
    erb('pgss_table').result(binding)
  end

  def render_summary_table
    erb('summary_table').result(binding)
  end

  def erb(template)
    ERB.new(File.read("templates/#{template}.erb"), trim_mode: '<>%')
  end

  def total_size_change(migration)
    size_change_bytes = migration.statistics.total_database_size_change

    return UNKNOWN if size_change_bytes.nil?

    sign = size_change_bytes < 0 ? '-' : '+'
    size_change = Filesize.from("#{size_change_bytes.abs} B").pretty

    sign + size_change
  end

  def success(migration)
    return UNKNOWN if migration.statistics.success.nil?

    migration.statistics.success ? ":white_check_mark:" : ":boom:"
  end

  def walltime(migration)
    return UNKNOWN if migration.statistics.walltime.nil?

    format_time(migration.statistics.walltime, unit: 's')
  end

  def format_int(number)
    Integer(number)
  end

  def format_time(time, unit: 'ms')
    return nil unless time

    "#{Float(time).round(1)} #{unit}"
  end

  def format_query(query)
    Niceql::Prettifier.prettify_sql(query)
      .gsub(' ', '&nbsp;')
      .gsub('/*', '&#x2F;&#x2A;')
      .gsub('*/', '&#x2A;&#x2F;')
      .gsub("\n", '<br />')
  rescue StandardError => e
    warn "Query formatting error:\n#{e}\nFor query: #{query}"
    query
  end

  def filter_pgss_query?(query)
    return true if query.downcase.start_with?(/commit|show|reset|begin|release savepoint|savepoint|set|rollback/)
    return true if query.include?('/* pgssignore /*')

    exclusions = [
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
    ].map(&:downcase)

    return true if exclusions.include?(query.downcase)

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
