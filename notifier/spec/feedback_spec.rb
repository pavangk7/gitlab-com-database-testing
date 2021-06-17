# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Feedback do
  # This is an end-to-end test based on the checked in fixtures
  # This is a temporary measure to increase our confidence in a change - we can remove
  # it if it gets tedious and we have smaller unit tests in place
  describe 'end to end test for rendering feedback comment' do
    let(:clone_details) { file_fixture('migration-testing/clone-details.json') }
    let(:migration_stats) { file_fixture('migration-testing/migration-stats.json') }
    let(:migrations) { file_fixture('migration-testing/migrations.json') }

    let(:result) { Result.from_files(migration_stats, migrations, clone_details) }

    subject { described_class.new(result).render }

    it 'renders the comment for fixtures' do
      expect(subject).to eq(File.read(file_fixture('migration-testing/expected-comment.txt')))
    end
  end
end
