# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Warnings do
  let(:result) { MultiDbResult.from_directory(file_fixture('migration-testing/v4')).per_db_results['main'] }
  let(:migration) { result.migrations[20210604232017] }

  subject(:warnings) { described_class.new(result) }

  describe '#render' do
    it 'renders a few things' do
      allow(migration).to receive(:success?).and_return(false)
      allow(migration).to receive(:walltime).and_return(Migration::SRE_NOTIFICATION_GUIDANCE * 2)
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
      expect(subject.render).to include('[background migration]')
      expect(subject.render).to include('[post-deploy migration]')
      expect(subject.render).to include('(`@gitlab-org/release/managers`)')
      expect(subject.render).to include('222.49')
    end

    it 'excludes migrations not introduced on current branch' do
      excluded_name = 'UnrelatedMigration'
      expect(result.other_migrations.map(&:name)).to include(excluded_name)
      expect(subject.render).not_to include(excluded_name)
    end
  end
end
