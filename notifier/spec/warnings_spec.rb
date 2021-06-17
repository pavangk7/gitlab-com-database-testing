# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Warnings do
  let(:clone_details) { file_fixture('migration-testing/clone-details.json') }
  let(:result) { Result.from_files(migration_stats, migrations, clone_details, query_details_dir) }
  let(:migration) { result.migrations[20210604232017] }
  let(:migration_stats) { file_fixture('migration-testing/migration-stats.json') }
  let(:migrations) { file_fixture('migration-testing/migrations.json') }
  let(:query_details_dir) { file_fixture('migration-testing/') }

  subject(:warnings) { described_class.new(result) }

  describe '#render' do
    it 'renders a few things' do
      allow(migration).to receive(:exceeds_time_guidance?).and_return(true)
      allow(migration).to receive(:success?).and_return(false)
      allow(migration).to receive(:queries_with_warnings).and_return(
        [Query.new({
                     "query" => "select * from users limit 1000 /*application:test*/",
                     "calls" => 1,
                     "total_time" => 222.49203,
                     "max_time" => 222.49203,
                     "mean_time" => 222.49203,
                     "rows" => 1
                   })])

      expect(subject.render).to include('did not complete')
      expect(subject.render).to include('This migration should not exceed')
      expect(subject.render).to include('should not exceed 100ms')
      expect(subject.render).to include('222.49203')
    end
  end
end
