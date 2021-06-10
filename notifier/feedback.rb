# frozen_string_literal: true
require 'filesize'
require 'erb'
require_relative 'niceql'

class Feedback
  UNKNOWN = ':grey_question:'

  attr_reader :result

  def initialize(result)
    @result = result
  end

  def render
    erb('feedback').result(binding)
  end

  private

  def migrations_from_branch
    all_migrations.select(&:intro_on_current_branch?)
  end

  def other_migrations
    all_migrations.reject(&:intro_on_current_branch)
  end

  def all_migrations
    result.migrations.values
  end

  def render_details(migration)
    erb('detail').result(binding)
  end

  def render_clone_details(clone_details)
    erb('clone_details').result(binding)
  end

  def render_pgss_table(pgss)
    erb('pgss_table').result(binding)
  end

  def render_migrations_from_branch_summary
    b = binding
    b.local_variable_set(:migrations, migrations_from_branch)
    erb('summary_table').result(b)
  end

  def render_other_migrations_summary
    b = binding
    b.local_variable_set(:migrations, other_migrations)
    erb('summary_table').result(b)
  end

  def erb(template)
    ERB.new(File.read("templates/#{template}.erb"), trim_mode: '<>%')
  end

  def total_size_change(migration)
    size_change_bytes = migration.total_database_size_change

    return UNKNOWN if size_change_bytes.nil?

    sign = size_change_bytes.negative? ? '-' : '+'
    size_change = Filesize.from("#{size_change_bytes.abs} B").pretty

    sign + size_change
  end

  def success(migration)
    return UNKNOWN if migration.success.nil?

    migration.success? ? ":white_check_mark:" : ":boom:"
  end

  def walltime(migration)
    return UNKNOWN if migration.walltime.nil?

    format_time(migration.walltime, unit: 's')
  end

  def type(migration)
    migration.type.tr("_", " ").capitalize
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
end
