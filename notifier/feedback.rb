# frozen_string_literal: true
require 'filesize'
require 'erb'
require 'active_support/core_ext/module/delegation'
require_relative 'niceql'
require 'pg_query'
require_relative 'json_payload'
require_relative 'environment'

class Feedback
  UNKNOWN = ':grey_question:'

  attr_reader :result, :env

  delegate :migrations_from_branch, :other_migrations, :background_migrations, to: :result

  def initialize(result, env = Environment.instance)
    @result = result
    @env = env
  end

  def render
    erb('feedback').result(binding)
  end

  private

  def render_details(migration)
    erb('detail').result(binding)
  end

  def render_background_migration_detail(background_migration)
    erb('background_migration_detail').result(binding)
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

  def render_json_payload
    payload = JsonPayload.new.encode(result)

    b = binding
    b.local_variable_set(:payload, payload)
    erb('json_payload').result(b)
  end

  def render_new_table(query)
    b = binding
    erb('new_table').result(b)
  end

  def render_new_table_details
    b = binding
    b.local_variable_set(:migrations, migrations_from_branch)
    erb('new_table_details').result(b)
  end

  def render_all_migrations_histogram
    Charts::ExecutionHistogram.for_result(result).render
  end

  def render_migration_histogram(migration)
    Charts::ExecutionHistogram.for_migration(migration).render
  end

  def render_background_migration_batch_histogram(background_migration)
    Charts::ExecutionHistogram.for_background_migration_batches(background_migration).render
  end

  def render_background_migration_query_histogram(background_migration)
    Charts::ExecutionHistogram.for_background_migration_queries(background_migration).render
  end

  def erb(template)
    ERB.new(File.read("templates/#{template}.erb"), trim_mode: '<>%')
  end

  def warnings
    Warnings.new(result)
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
    return ':boom:' unless migration.success?
    return ':warning:' if migration.warning?

    ':white_check_mark:'
  end

  def warning(migration)
    return UNKNOWN if migration.success.nil?
    return ':boom:' unless migration.success?
    return ':warning:' if migration.warning?
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
end
