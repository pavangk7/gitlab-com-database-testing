# frozen_string_literal: true

class MultiDbFeedback
  attr_reader :multi_db_result

  def initialize(multi_db_result)
    @multi_db_result = multi_db_result
  end

  def render
    erb('multi_db_feedback').result(binding)
  end

  def erb(template)
    ERB.new(File.read("templates/#{template}.erb"), trim_mode: '<>%')
  end
end
