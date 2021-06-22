# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Query do
  let(:pgss) do
    {
      "query" => "select pg_database_size(current_database()) /*application:test*/",
      "calls" => 1,
      "total_time" => 269.888734,
      "max_time" => 269.888734,
      "mean_time" => 269.888734,
      "rows" => 0
    }
  end

  subject(:query) { described_class.new(pgss) }

  it 'inits from a pgpass row' do
    expect { subject }.not_to raise_error
  end

  describe 'excluded?' do
    it 'is true if query is on the excluded list' do
      subject.query = described_class::EXCLUSIONS.first

      expect(subject.excluded?).to be true
    end

    it 'is true if query includes /* pgssignore /*' do
      subject.query = "#{subject.query} /* pgssignore */"

      expect(subject.excluded?).to be true
    end

    it 'is true if query table is ar_internal_metadata' do
      subject.query = "SELECT * from ar_internal_metadata;"

      expect(subject.excluded?).to be true
    end

    it 'is true if query table starts with pg_' do
      subject.query = "SELECT * from pg_internal_nonsense;"

      expect(subject.excluded?).to be true
    end

    it 'is false for other queries' do
      subject.query = "SELECT * from user;"

      expect(subject.excluded?).to be false
    end
  end

  describe '#exceeds_time_guidance?' do
    it 'returns true if max time greater than QUERY_GUIDANCE_MILLISECONDS' do
      subject.max_time = described_class::QUERY_GUIDANCE_MILLISECONDS * 2

      expect(subject.exceeds_time_guidance?).to be true
    end

    it 'returns false if concurrent operations are below 5 minutes' do
      pgss['query'] = 'CREATE INDEX CONCURRENTLY index_ci_runners_on_token_lower '\
                         'ON ci_runners (LOWER(token)) /*application:test*/'

      expect(subject.exceeds_time_guidance?).to be false
    end

    it 'returns false if max time less than QUERY_GUIDANCE_MILLISECONDS' do
      subject.max_time = described_class::QUERY_GUIDANCE_MILLISECONDS / 2

      expect(subject.exceeds_time_guidance?).to be false
    end
  end

  context 'when query has special characters' do
    let(:pgss) do
      {
        "query" => "CREATE INDEX CONCURRENTLY \"tmp_index_merge_requests_draft_and_status\""\
                   " ON \"merge_requests\" (\"id\") WHERE draft = false AND state_id = 1 AND "\
                   "((title)::text ~* '^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP'::text) "\
                   "/*application:test*/",
        "calls" => 1,
        "total_time" => 1824825.496259,
        "max_time" => 1824825.496259,
        "mean_time" => 1824825.496259,
        "rows" => 0
      }
    end

    it 'replaces the pipe character with &#124;' do
      expect(subject.formatted_query).not_to include('|')
    end
  end
end
