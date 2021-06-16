# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feedback do
  subject(:feedback) { described_class.new(Result.new(migrations, nil)) }

  let(:migrations) do
    # rubocop:disable Metrics/LineLength
    {
      4 => Migration.new({ 'version' => 4, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => true }, nil),
      3 => Migration.new({ 'version' => 3, 'type' => Migration::TYPE_REGULAR, 'intro_on_current_branch' => true }, nil),
      1 => Migration.new({ 'version' => 1, 'type' => Migration::TYPE_REGULAR, 'intro_on_current_branch' => true }, nil),
      2 => Migration.new({ 'version' => 2, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => true }, nil),
      5 => Migration.new({ 'version' => 5, 'type' => Migration::TYPE_REGULAR, 'intro_on_current_branch' => false }, nil),
      6 => Migration.new({ 'version' => 6, 'type' => Migration::TYPE_POST_DEPLOY, 'intro_on_current_branch' => false }, nil)
    }
    # rubocop:enable Metrics/LineLength
  end

  describe '#migrations_from_branch' do
    it 'orders by type and version' do
      expect(feedback.migrations_from_branch.map(&:version)).to eq([1, 3, 2, 4])
    end
  end

  describe '#other_migrations' do
    subject(:feedback) { described_class.new(Result.new(other_migrations, nil)) }

    let(:other_migrations) { migrations.each { |_, v| v.intro_on_current_branch = !v.intro_on_current_branch } }

    it 'orders by type and version' do
      expect(feedback.other_migrations.map(&:version)).to eq([1, 3, 2, 4])
    end
  end
end
