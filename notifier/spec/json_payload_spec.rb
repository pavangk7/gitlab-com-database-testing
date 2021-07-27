# frozen_string_literal: true
require 'spec_helper'
require "base64"

RSpec.describe JsonPayload do
  let(:clone_details) { file_fixture('migration-testing/clone-details.json') }
  let(:migration_stats) { file_fixture('migration-testing/migration-stats.json') }
  let(:migrations) { file_fixture('migration-testing/migrations.json') }
  let(:query_details_dir) { file_fixture('migration-testing/') }

  let(:result) { Result.from_files(migration_stats, migrations, clone_details, query_details_dir) }

  subject do
    encoded = described_class.new.encode(result)

    JSON.parse(Base64.decode64(encoded))
  end

  it 'stores a version' do
    expect(subject['version']).to eq(described_class::VERSION)
  end

  it 'has data for migrations on the branch' do
    result.migrations_from_branch.map(&:version).each do |version|
      records = subject['data'].select { |record| record['migration'] == version }

      expect(records.size).to eq(1)
    end
  end

  it 'stores walltime for each migration' do
    subject['data'].each do |record|
      expect(record['walltime']).to be_positive
    end
  end

  it 'stores database size change for each migration' do
    subject['data'].each do |record|
      expect(record['total_database_size_change']).to be_a(Integer)
    end
  end

  it 'stores success for each migration' do
    subject['data'].each do |record|
      expect(record['success']).to be_boolean
    end
  end
end
