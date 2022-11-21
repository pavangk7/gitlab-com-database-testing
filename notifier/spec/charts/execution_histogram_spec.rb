# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Charts::ExecutionHistogram do
  let(:executions) do
    now = Time.current
    [0.01, 0.1, 0.5, 1, 60, 350, 1000].map do |i|
      QueryExecution.new({
                           "start_time" => now.iso8601(6),
                           "end_time" => (now + i.seconds).iso8601(6),
                           "binds" => []
                         })
    end
  end

  subject { described_class.new(executions, title: 'Some Histogram', column_label: 'Query Runtime') }

  describe '#buckets' do
    it 'has buckets for every execution' do
      expect(subject.data.values.sum(&:size)).to eq(executions.count)
    end

    it 'puts each execution in the correct bucket' do
      subject.data.each do |bucket, values|
        values.each { |v| expect(bucket).to include(v.duration) }
      end
    end
  end

  describe '#bucket_label' do
    it 'makes sense for a closed range' do
      expect(subject.bucket_label(1.second..5.seconds)).to eq('1 second - 5 seconds')
    end

    it 'makes sense for an open range' do
      expect(subject.bucket_label(1.second..)).to eq('1 second +')
    end
  end

  describe '#template' do
    context 'when executions are empty' do
      let(:executions) { [] }

      it { expect(subject.template).to eq('templates/charts/placeholder.erb') }
    end

    context "when there's executions to render" do
      it { expect(subject.template).to eq('templates/charts/histogram.erb') }
    end
  end

  describe '#render' do
    it 'renders' do
      rendered = subject.render

      aggregate_failures do
        expect(rendered).to include(subject.title)
        subject.buckets.each do |b|
          expect(rendered).to include(subject.bucket_label(b))
        end
      end
    end
  end
end
