# frozen_string_literal: true
require 'singleton'

class Environment
  include Singleton

  def ci_project_url
    ENV['CI_PROJECT_URL']
  end

  def ci_job_id
    ENV['CI_JOB_ID']
  end

  def ci_pipeline_id
    ENV['CI_PIPELINE_ID']
  end
end
