# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QueryExclusion do
  it 'is true if query is on the excluded list' do
    query = described_class::EXCLUSIONS.first

    expect(described_class.exclude?(query)).to be true
  end

  it 'is true if the query differs from the excluded list only by a comment' do
    query = described_class::EXCLUSIONS.first

    query_with_comment = "#{query} /* some comment */"

    expect(described_class.exclude?(query_with_comment)).to be true
  end

  it 'is true if query includes /* pgssignore /*' do
    query = "SELECT 1 /* pgssignore */"

    expect(described_class.exclude?(query)).to be true
  end

  it 'is true if query table is ar_internal_metadata' do
    query = "SELECT * from ar_internal_metadata;"

    expect(described_class.exclude?(query)).to be true
  end

  it 'is true if query table starts with pg_' do
    query = "SELECT * from pg_internal_nonsense;"

    expect(described_class.exclude?(query)).to be true
  end

  it 'is false for other queries' do
    query = "SELECT * from user;"

    expect(described_class.exclude?(query)).to be false
  end
end
