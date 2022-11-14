# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Result do
  where(:fixture_root, :schema_version, :database) do
    [
      ['v4', 4, 'main'],
      ['v4', 4, 'ci']
    ]
  end

  with_them do
    let(:root_testing_path) { file_fixture("migration-testing/#{fixture_root}") }
    let(:per_db_testing_path) { file_fixture("migration-testing/#{fixture_root}/#{database}") }
    let(:clone_details) { File.join(root_testing_path, "clone-details.json") }

    subject(:result) { MultiDbResult.from_directory(root_testing_path).per_db_results[database] }

    it 'identifies the correct schema version' do
      expect(described_class.schema_version(per_db_testing_path)).to eq(schema_version)
    end

    it 'loads clone details' do
      detail_names = result.clone_details.map(&:cloneId)
      expect(detail_names).to contain_exactly(
        "database-testing-1448027-8121647-main", "database-testing-1448027-8121647-ci"
      )
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
        subject(:result) { described_class.new(migrations, [], clone_details, database) }

        it 'returns migrations from the branch ordered by type and version' do
          expect(result.migrations_from_branch.map(&:version)).to eq([1, 3, 2, 4])
        end
      end

      describe '#other_migrations' do
        subject(:result) { described_class.new(migrations, [], clone_details, database) }

        it 'returns other migrations ordered by type and version' do
          expect(result.other_migrations.map(&:version)).to eq([6, 8, 5, 7])
        end
      end
    end
  end
end
