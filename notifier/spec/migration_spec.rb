# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Migration do
  let(:excluded_query) do
    {
      "query" => "select pg_database_size(current_database()) /*application:test*/",
      "calls" => 1,
      "total_time" => 87.621755,
      "max_time" => 87.621755,
      "mean_time" => 87.621755,
      "rows" => 1
    }
  end

  let(:included_good_query) do
    {
      "query" => "select * from users limit 1 /*application:test*/",
      "calls" => 1,
      "total_time" => 80.51234,
      "max_time" => 80.51234,
      "mean_time" => 80.51234,
      "rows" => 1
    }
  end
  let(:good_queries) { [excluded_query, included_good_query]}

  let(:bad_query) do
    {
      "query" => "select * from users limit 1000 /*application:test*/",
      "calls" => 1,
      "total_time" => 222.49203,
      "max_time" => Query::QUERY_GUIDANCE_MILLISECONDS * 2,
      "mean_time" => 222.49203,
      "rows" => 1
    }
  end

  let(:queries) { good_queries << bad_query }

  let(:stats) do
    {
      "migration" => 20210602144718,
      "walltime" => 1.9509822260588408,
      "success" => true,
      "total_database_size_change" => 32768,
      "query_statistics" => queries
    }
  end

  let(:migration_hash) do
    {
      "version" => 20210602144718,
      "path" => "db/migrate/20210602144718_create_test_table.rb",
      "name" => "CreateTestTable",
      "type" => "regular",
      "intro_on_current_branch" => true
    }
  end

  subject(:migration) { described_class.new(migration_hash, stats, []) }

  it 'loads from the result json hash' do
    expect { subject }.not_to raise_error
  end

  it 'collects queries into query objects' do
    expect(subject.queries.size).to eq(3)
    expect(subject.queries.first).to be_a(Query)
  end

  describe '#was_run?' do
    it 'returns false if the migration has no statistics' do
      subject = described_class.new(migration_hash, nil, [])

      expect(subject.was_run?).to be false
    end

    it 'returns true if the migration has statistics' do
      expect(subject.was_run?).to be true
    end
  end

  describe '#exceeds_time_guidance?' do
    context 'with a regular migration' do
      before do
        migration_hash['type'] = described_class::TYPE_REGULAR
      end

      it 'returns false if under REGULAR_MIGRATION_GUIDANCE_SECONDS' do
        stats['walltime'] = described_class::REGULAR_MIGRATION_GUIDANCE_SECONDS / 2

        expect(subject.exceeds_time_guidance?).to be false
      end

      it 'returns true if over REGULAR_MIGRATION_GUIDANCE_SECONDS' do
        stats['walltime'] = described_class::REGULAR_MIGRATION_GUIDANCE_SECONDS + 30

        expect(subject.exceeds_time_guidance?).to be true
      end
    end

    context 'with a post_deploy migration' do
      before do
        migration_hash['type'] = described_class::TYPE_POST_DEPLOY
      end

      it 'returns false if under POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS' do
        stats['walltime'] = described_class::POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS / 2

        expect(subject.exceeds_time_guidance?).to be false
      end

      it 'returns true if over POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS' do
        stats['walltime'] = described_class::POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS + 30

        expect(subject.exceeds_time_guidance?).to be true
      end
    end
  end

  describe '#queries_with_warnings' do
    it 'finds queries that exceed timing guidelines' do
      expect(subject.queries_with_warnings.size).to eq(1)
    end
  end

  describe '#warning?' do
    let(:queries) { good_queries }

    it 'is false if everything works' do
      expect(subject.warning?).to be false
    end

    it 'is true if not successful' do
      subject.success = false

      expect(subject.warning?).to be true
    end

    it 'is true if migration took too long' do
      subject.walltime = described_class::POST_DEPLOY_MIGRATION_GUIDANCE_SECONDS * 5

      expect(subject.warning?).to be true
    end

    it 'is true if a query took too long' do
      queries << bad_query

      expect(subject.warning?).to be true
    end
  end

  describe '#important_queries' do
    it 'returns only unexcluded queries' do
      expect(subject.important_queries.size).to eq(2)
    end
  end

  describe '#sort_key' do
    it 'returns a representation of type and version' do
      post_migration = described_class.new(
        { 'version' => 42, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => true },
        nil,
        []
      )

      expect(subject.sort_key).to eq([0, 20210602144718])
      expect(post_migration.sort_key).to eq([1, 42])
    end
  end

  describe '#excluded_query_duration' do
    it 'is the sum of the duration of all excluded queries' do
      expect(subject.excluded_query_duration).to eq(excluded_query['total_time'])
    end
  end
end
