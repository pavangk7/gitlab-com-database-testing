# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Feedback do
  # This is an end-to-end test based on the checked in fixtures
  # This is a temporary measure to increase our confidence in a change - we can remove
  # it if it gets tedious and we have smaller unit tests in place
  describe 'end to end test for rendering feedback comment' do
    let(:clone_details) { file_fixture('migration-testing/clone-details.json') }
    let(:migration_stats) { file_fixture('migration-testing/up/migration-stats.json') }
    let(:migrations) { file_fixture('migration-testing/migrations.json') }
    let(:query_details_dir) { file_fixture('migration-testing/up/') }

    let(:result) { Result.from_files(migration_stats, migrations, clone_details, query_details_dir) }

    let(:expected_comment_file) { file_fixture('migration-testing/expected-comment.txt') }

    subject { described_class.new(result).render }

    before do
      override_env_from_fixture('migration-testing/environment.json')
    end

    # The expectation for this spec lives in `expected_comment_file`
    # It can be re-recorded with: `RECAPTURE_END_TO_END_RESULTS=1 bundle exec rspec spec`
    it 'renders the comment for fixtures' do
      if ENV['RECAPTURE_END_TO_END_RESULTS']
        File.open(expected_comment_file, 'wb+') do |io|
          io << subject
        end
      end

      expect(subject).to eq(File.read(expected_comment_file))
    end
  end
end
