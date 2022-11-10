# frozen_string_literal: true

require 'spec_helper'
require 'json'

test_migrations = {
  existing: {
    filename: 'db/migrate/20211224114539_add_packages_cleanup_package_file_worker_capacity_check_constraint_to_app_settings.rb',
    content: File.read('spec/fixtures/migrations/existing_migration.rb')
  },
  new: {
    filename: 'db/migrate/20220914080716_add_index_to_candidate_id_and_name_on_ml_candidate_params.rb',
    content: File.read('spec/fixtures/migrations/new_migration.rb')
  }
}

RSpec.describe MigrationLister do
  let(:lister) { described_class.new }
  let(:git_payload) do
    "A\t#{test_migrations[:new][:filename]}"
  end

  before do
    test_migrations.each do |_, tm|
      allow(File).to receive(:read).with(tm[:filename]).and_return(tm[:content])
    end
    allow(Dir).to receive(:glob).and_return(
      [
        test_migrations[:existing][:filename],
        test_migrations[:new][:filename]
      ]
    )
    allow_any_instance_of(described_class).to receive(:read_from_git).and_return(git_payload)
    allow(File).to receive(:directory?).with('db/migrate').and_return(true)
    allow(File).to receive(:directory?).with('db/post_migrate').and_return(true)
  end

  context 'there is a new migration' do
    it 'returns the expected structure' do
      expect(lister.migrations.length).to eq(2)
    end

    it 'has the expected keys on each migration' do
      lister.migrations.each do |_, v|
        %i[version path name type intro_on_current_branch].each do |k|
          expect(v).to have_key(k)
        end
      end
    end

    it 'sets the "intro_on_current_branch" flag for new migrations' do
      expect(lister.migrations[20_220_914_080_716][:intro_on_current_branch]).to be true
    end
  end

  context 'there is a new migration and a deleted migration' do
    let(:git_payload) do
      "D\tDeletedMigration.rb\nA\t#{test_migrations[:new][:filename]}"
    end

    it 'does not include the deleted migration' do
      expect(lister.migrations.length).to eq(2)
    end
  end
end
