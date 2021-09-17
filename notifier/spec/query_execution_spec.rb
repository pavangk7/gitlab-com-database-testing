# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QueryExecution do
  def make_execution(sql:, binds: [], start_time: Time.current.rfc3339, end_time: Time.current.rfc3339)
    QueryExecution.new({ "sql" => sql, "binds" => binds, "start_time" => start_time, "end_time" => end_time })
  end

  describe '#excluded?' do
    it 'delegates to QueryExclusion' do
      execution = make_execution(sql: 'foo')
      result = double
      expect(QueryExclusion).to receive(:exclude?).with(execution.sql).and_return(result)
      expect(execution.excluded?).to eq(result)
    end
  end
end
