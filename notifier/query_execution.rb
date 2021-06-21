# frozen_string_literal: true

class QueryExecution
  attr_accessor :sql, :start_time, :end_time, :binds

  def initialize(data)
    @sql, @binds, start_time, end_time = data.values_at("sql", "binds", "start_time", "end_time")
    @start_time = Time.rfc3339(start_time)
    @end_time = Time.rfc3339(end_time)
  end

  def duration
    ActiveSupport::Duration.build(end_time - start_time)
  end
end
