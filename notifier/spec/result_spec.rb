# frozen_string_literal: true

require 'spec_helper'

describe Result do
  let(:clone_details) { file_fixture('migration-testing/clone-details.json') }
  let(:migration_stats) { file_fixture('migration-testing/migration-stats.json') }
  let(:migrations) { file_fixture('migration-testing/migrations.json') }

  subject(:result) { described_class.from_files(migration_stats, migrations, clone_details) }

  it 'loads clone details' do
    expect(result.clone_details.cloneId).to eq('database-testing-639298')
  end

  it 'loads migrations' do
    expect(result.migrations).not_to be_empty
  end
end
