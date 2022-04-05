# frozen_string_literal: true

class Migration
  REGULAR_MIGRATION_GUIDANCE_SECONDS = 3.minutes.freeze
  POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS = 10.minutes.freeze
  SRE_NOTIFICATION_GUIDANCE = 20.minutes.freeze
  TYPE_REGULAR = 'regular'
  TYPE_POST_DEPLOY = 'post_deploy'
  TYPE_BACKGROUND = 'background'
  TIMING_GUIDELINES = 'https://docs.gitlab.com/ee/development/database_review.html#timing-guidelines-for-migrations'
  POST_DEPLOY_MIGRATION_GUIDE = 'https://docs.gitlab.com/ee/development/post_deployment_migrations.html'
  BACKGROUND_MIGRATION_GUIDE = 'https://docs.gitlab.com/ee/development/background_migrations.html'

  def self.background_migration_batch_from_directory(directory)
    query_details_path = directory.join('query-details.json')
    query_details = if File.exist?(query_details_path)
                      JSON.parse(File.read(query_details_path))
                    else
                      []
                    end

    stats = JSON.parse(File.read(directory.join('migration-stats.json')))

    migration_data = {
      version: nil,
      name: directory.basename.to_s,
      type: TYPE_BACKGROUND,
      path: nil,
      intro_on_current_branch: true
    }

    new(migration_data, stats, query_details)
  end

  def self.from_directory(directory, global_migration_data:)
    query_details_path = directory.join('query-details.json')
    query_details = if File.exist?(query_details_path)
                      JSON.parse(File.read(query_details_path))
                    else
                      []
                    end

    stats = JSON.parse(File.read(directory.join('migration-stats.json')))
    type, path, intro_on_current_branch = global_migration_data[stats['version'].to_s]
                                            .values_at('type', 'path', 'intro_on_current_branch')
    migration_data = {
      version: stats['version'],
      name: directory.basename.to_s, # Otherwise name is a Pathname
      type: type,
      path: path,
      intro_on_current_branch: intro_on_current_branch
    }.stringify_keys

    new(migration_data, stats, query_details)
  end

  attr_accessor :version, :name, :statistics, :total_database_size_change,
                :queries, :type, :walltime, :intro_on_current_branch, :success,
                :query_executions

  # So that migration durations can be plotted directly in execution histogram charts
  alias_method :duration, :walltime

  def initialize(migration, stats, query_details)
    @version = migration['version']
    @path = migration['path']
    @name = migration['name']
    @type = migration['type']
    @intro_on_current_branch = migration['intro_on_current_branch']
    @query_executions = query_details.map { |qd| QueryExecution.new(qd) }
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

  def sre_should_be_informed?
    walltime > SRE_NOTIFICATION_GUIDANCE
  end

  def exceeds_time_guidance?
    walltime > time_guidance
  end

  def important_queries
    queries.reject(&:excluded?)
  end

  def important_query_executions
    query_executions.reject(&:excluded?)
  end

  def queries_with_warnings
    @queries_with_warnings ||= important_queries.select(&:exceeds_time_guidance?)
  end

  def has_queries_with_warnings?
    queries_with_warnings.any?
  end

  def name_formatted
    "<b>#{version} - #{name}</b>"
  end

  def walltime_minutes
    "#{walltime.in_minutes.round(2)}min"
  end

  def time_guidance_minutes
    "#{time_guidance.in_minutes.round(2)}min"
  end

  def warnings
    warnings = queries_with_warnings.map { |q| q.warning(name_formatted) }

    warnings << "#{name_formatted} did not complete successfully, check the job log for details" unless success?

    if sre_should_be_informed?
      warnings << "#{name_formatted} took #{walltime_minutes}. Please add a comment that mentions Release "\
                  "Managers (`@gitlab-org/release/managers`) so they are informed."
    end

    warnings << time_remedy if exceeds_time_guidance?

    warnings
  end

  def time_remedy
    if type == TYPE_REGULAR && walltime < POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS
      "#{name_formatted} may need a [post-deploy migration](#{POST_DEPLOY_MIGRATION_GUIDE}) "\
      "to comply with [timing guidelines](#{TIMING_GUIDELINES}). It took #{walltime_minutes}, "\
      "but should not exceed #{time_guidance_minutes}"
    else
      "#{name_formatted} may need a [background migration](#{BACKGROUND_MIGRATION_GUIDE}) to "\
      "comply with [timing guidelines](#{TIMING_GUIDELINES}). It took #{walltime_minutes}, "\
      "but should not exceed #{time_guidance_minutes}"
    end
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
    @walltime = stats['walltime'].seconds
    @success = stats['success']
    @statistics = stats
    init_queries(stats)
  end

  def init_queries(stats)
    @queries = stats['query_statistics'].map do |query|
      Query.new(query)
    end
  end

  def sort_key
    [type == TYPE_REGULAR ? 0 : 1, version]
  end
end
