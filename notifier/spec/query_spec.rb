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
    it 'delegates to QueryExclusion' do
      result = double
      expect(QueryExclusion).to receive(:exclude?).with(subject.query).and_return(result)
      expect(subject.excluded?).to eq(result)
    end
  end

  describe '#new_table_fields_and_types' do
    let(:pgss) { { "query" => query } }

    let(:query) do
      <<~SQL
        CREATE TABLE accounts (
          user_id serial PRIMARY KEY,
          username VARCHAR ( 50 ) UNIQUE NOT NULL,
          password VARCHAR ( 50 ) NOT NULL,
          email VARCHAR ( 255 ) UNIQUE NOT NULL,
          created_on TIMESTAMP NOT NULL,
          last_login TIMESTAMP
        );
      SQL
    end

    let(:result) do
      [ ['user_id', 'serial'], ['username', 'varchar'], ['password', 'varchar'], ['email', 'varchar'], ['created_on', 'timestamp'], ['last_login', 'timestamp'] ]
    end

    it 'returns column names and data types' do
      expect(subject.new_table_fields_and_types).to eql(result)
    end

    context 'when is not a create table statement' do
      let(:query) { 'select pg_database_size(current_database()) /*application:test*/'}

      it 'returns nil' do
        expect(subject.new_table_fields_and_types).to be_nil
      end
    end
  end

  describe '#formatted_query' do
    let(:normalized_query) { 'Select $1 from users where email=$2 limit $3' }

    context 'when the query is not normalized' do
      let(:pgss) do
        {
          "query" => "Select 'somevalue' from users where email='user@gitlab.com' limit 1",
          "calls" => 1,
          "total_time" => 1824825.496259,
          "max_time" => 1824825.496259,
          "mean_time" => 1824825.496259,
          "rows" => 0
        }
      end

      it 'returns a normalized query' do
        expect(subject.formatted_query).to eql(normalized_query)
      end
    end

    context 'when the query is already normalized' do
      let(:pgss) do
        {
          "query" => "Select $1 from users where email=$2 limit $3",
          "calls" => 1,
          "total_time" => 1824825.496259,
          "max_time" => 1824825.496259,
          "mean_time" => 1824825.496259,
          "rows" => 0
        }
      end

      it 'returns a normalized query' do
        expect(subject.formatted_query).to eql(normalized_query)
      end
    end

    context 'when query is of type "CREATE TRIGGER ... EXECUTE FUNCTION ..."' do
      let(:pgss) do
        # rubocop:disable Layout/LineLength
        {
          "query" => "CREATE TRIGGER trigger_has_external_wiki_on_delete_new AFTER DELETE ON integrations FOR EACH ROW WHEN (((old.type_new)::text = 'Integrations::ExternalWiki'::text) AND (old.project_id IS NOT NULL)) EXECUTE FUNCTION set_has_external_wiki(); /*application:test*/",
          "calls" => 1,
          "total_time" => 1824825.496259,
          "max_time" => 1824825.496259,
          "mean_time" => 1824825.496259,
          "rows" => 0
        }
        # rubocop:enable Layout/LineLength
      end

      it 'parse it successfully' do
        expect { query.formatted_query }.not_to raise_error
      end
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
