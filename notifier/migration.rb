# frozen_string_literal: true

class Migration
  REGULAR_MIGRATION_GUIDANCE_SECONDS = (3 * 60)
  POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS = (10 * 60)
  TYPE_REGULAR = 'regular'
  TYPE_POST_DEPLOY = 'post_deploy'

  attr_accessor :version, :path, :name, :statistics, :total_database_size_change,
                :queries, :type, :walltime, :intro_on_current_branch, :success

  def initialize(migration, stats)
    @version = migration['version']
    @path = migration['path']
    @name = migration['name']
    @type = migration['type']
    @intro_on_current_branch = migration['intro_on_current_branch']

    init_stats(stats)
  end

  def intro_on_current_branch?
    intro_on_current_branch
  end

  def success?
    @success
  end

  def was_run?
    @was_run
  end

  def time_guidance
    return REGULAR_MIGRATION_GUIDANCE_SECONDS if type == TYPE_REGULAR
    return POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS if type == TYPE_POST_DEPLOY

    raise 'Unknown migration type'
  end

  def exceeds_time_guidance?
    walltime > time_guidance
  end

  def queries_with_warnings
    @queries_with_warnings ||= queries.select(&:exceeds_time_guidance?)
  end

  def has_queries_with_warnings?
    queries_with_warnings.any?
  end

  def warning?
    !success? || exceeds_time_guidance? || has_queries_with_warnings?
  end

  def init_stats(stats)
    unless stats
      @was_run = false
      return
    end

    @was_run = true
    @total_database_size_change = stats['total_database_size_change']
    @walltime = stats['walltime']
    @success = stats['success']
    @statistics = stats
    init_queries(stats)
  end

  def init_queries(stats)
    @queries = stats['query_statistics'].map do |query|
      Query.new(query)
    end
  end
end
