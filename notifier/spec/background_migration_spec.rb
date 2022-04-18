# frozen_string_literal: true
require 'spec_helper'

RSpec.describe BackgroundMigration do
  describe '.queries' do
    let(:queries_migration_1) do # query, calls, total_time, max_time, mean_time, rows
      [
        Query.new(
          { query: 'select 1', total_time: 100, max_time: 100, mean_time: 100, rows: 1, calls: 1 }.stringify_keys),
        Query.new(
          { query: 'select 1, 1', total_time: 200, max_time: 200, mean_time: 200, rows: 2, calls: 2 }.stringify_keys)
      ]
    end

    let(:background_migration) { described_class.new('bg', [migration_1, migration_2]) }

    let(:aggregate_query_1) { background_migration.queries.find { |q| q.query == 'select $1' } }
    let(:aggregate_query_2) { background_migration.queries.find { |q| q.query == 'select $1, $2' } }

    let(:queries_migration_2) do
      [
        Query.new({ query: 'select 1', total_time: 50, max_time: 50, mean_time: 50, rows: 3, calls: 3 }.stringify_keys),
        Query.new({ query: 'select 1', total_time: 25, max_time: 25, mean_time: 25, rows: 4, calls: 4 }.stringify_keys)
      ]
    end

    let(:migration_1) { double(Migration, queries: queries_migration_1) }
    let(:migration_2) { double(Migration, queries: queries_migration_2) }

    it 'has the correct number of aggregated queries' do
      expect(background_migration.queries.count).to eq(2)
    end

    it 'sums call counts per query text' do
      expect(aggregate_query_1.calls).to eq(8)
      expect(aggregate_query_2.calls).to eq(2)
    end

    it 'sums row counts per query text' do
      expect(aggregate_query_1.rows).to eq(8)
      expect(aggregate_query_2.rows).to eq(2)
    end

    it 'sums total_time per query text' do
      expect(aggregate_query_1.total_time).to eq(175)
      expect(aggregate_query_2.total_time).to eq(200)
    end

    it 'weighted averages mean query time by number of calls' do
      expect(aggregate_query_1.mean_time).to eq((100 * 1 + 50 * 3 + 25 * 4) / (1 + 3 + 4))
      expect(aggregate_query_2.mean_time).to eq(200)
    end

    it 'maxes max query time per query text' do
      expect(aggregate_query_1.max_time).to eq(100)
      expect(aggregate_query_2.max_time).to eq(200)
    end
  end
end
