# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Result do
  let(:clone_details) { file_fixture('migration-testing/clone-details.json') }
  let(:migration_stats) { file_fixture('migration-testing/migration-stats.json') }
  let(:migrations) { file_fixture('migration-testing/migrations.json') }
  let(:query_details_dir) { file_fixture('migration-testing/') }

  subject(:result) { described_class.from_files(migration_stats, migrations, clone_details, query_details_dir) }

  it 'loads clone details' do
    expect(result.clone_details.cloneId).to eq('database-testing-651277')
  end

  it 'loads migrations' do
    expect(result.migrations).not_to be_empty
  end

  describe 'sorting and filtering' do
    let(:migrations) do
      # rubocop:disable Layout/LineLength
      {
        4 => Migration.new({ 'version' => 4, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => true }, nil, []),
        3 => Migration.new({ 'version' => 3, 'type' => Migration::TYPE_REGULAR, 'intro_on_current_branch' => true }, nil, []),
        1 => Migration.new({ 'version' => 1, 'type' => Migration::TYPE_REGULAR, 'intro_on_current_branch' => true }, nil, []),
        2 => Migration.new({ 'version' => 2, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => true }, nil, []),
        8 => Migration.new({ 'version' => 8, 'type' => Migration::TYPE_REGULAR, 'intro_on_current_branch' => false }, nil, []),
        7 => Migration.new({ 'version' => 7, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => false }, nil, []),
        5 => Migration.new({ 'version' => 5, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => false }, nil, []),
        6 => Migration.new({ 'version' => 6, 'type' => Migration::TYPE_REGULAR, 'intro_on_current_branch' => false }, nil, [])
      }
      # rubocop:enable Layout/LineLength
    end

    describe '#migrations_from_branch' do
      subject(:result) { described_class.new(migrations, clone_details) }

      it 'returns migrations from the branch ordered by type and version' do
        expect(result.migrations_from_branch.map(&:version)).to eq([1, 3, 2, 4])
      end
    end

    describe '#other_migrations' do
      subject(:result) { described_class.new(migrations, clone_details) }

      it 'returns other migrations ordered by type and version' do
        expect(result.other_migrations.map(&:version)).to eq([6, 8, 5, 7])
      end
    end
  end
end
