require 'filesize'
require 'erb'
require 'niceql'
require 'pg_query'

class Feedback
  UNKNOWN = ':grey_question:'.freeze

  attr_reader :stats

  def initialize(stats)
    @stats = stats
  end

  def render
    partial('feedback')
  end

  private

  def partial(template)
    ERB.new(File.read("templates/#{template}.erb"), nil, '<>%').result(binding)
  end

  def render_details(migration)
    ERB.new(File.read("templates/detail.erb"), nil, '<>%').result(binding)
  end

  def render_pgss_table(pgss)
    ERB.new(File.read("templates/pgss_table.erb"), nil, '<>%').result(binding)
  end

  def total_size_change(migration)
    size_change_bytes = migration['total_database_size_change']

    return UNKNOWN unless size_change_bytes
    sign = (size_change_bytes < 0) ? '-' : '+'
    size_change = Filesize.from("#{size_change_bytes.abs} B").pretty

    sign + size_change
  end

  def success(migration)
    return UNKNOWN unless migration['success']

    (migration['success']) ? ":white_check_mark:" : ":boom:"
  end

  def walltime(migration)
    return UNKNOWN unless migration['walltime']

    format_time(migration['walltime'], unit: 's')
  end

  def format_int(number)
    Integer(number)
  end

  def format_time(time, unit: 'ms')
    "#{Float(time).round(1)} #{unit}"
  end

  def format_query(query)
    Niceql::Prettifier.prettify_sql(query)
      .gsub(' ', '&nbsp;')
      .gsub('/*', '&#x2F;&#x2A;')
      .gsub('*/', '&#x2A;&#x2F;')
      .gsub("\n", '<br />')
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
    ].map(&:downcase)

    return true if exclusions.include?(query.downcase)

    tables = PgQuery.parse(query).tables

    return false if tables.empty?

    return true if tables.all? { |table| table.start_with?('pg_') }
    return true if tables.uniq == ['ar_internal_metadata']

    false
  end
end
