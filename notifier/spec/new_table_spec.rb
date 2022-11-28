# frozen_string_literal: true
require 'spec_helper'

RSpec.describe NewTable do
  subject(:new_table) { described_class.new(columns) }

  let(:pg_data_types) { YAML.load_file('pg_data_types.yml') }

  describe '#optimize_column_order' do
    let(:columns) do
      [
        %w[i timestamp],
        %w[r varchar],
        %w[id integer],
        %w[m jsonb],
        %w[uuid uuid],
        %w[super_id bigint],
        %w[h numeric],
        %w[q bytea],
        %w[x oid],
        %w[can_travel boolean],
        %w[y double],
        %w[z time],
        %w[b text],
        %w[c date],
        %w[d smallint],
        %w[z character],
        %w[v inet],
        %w[l timestamp_with_time_zone]

      ]
    end

    let(:result) do
      [16, 8, 8, 8, 8, 8, 4, 4, 4, 2, 1, -1, -1, -1, -1, -1, -1, -1]
    end

    it 'returns best column order' do
      columns = new_table.optimize_column_order

      bytes_sorted = columns.map { |column| pg_data_types[column[1]] }

      expect(bytes_sorted).to eql(result)
    end
  end

  describe '#column_order_optimized?' do
    context 'when the column order is not optimized' do
      let(:columns) do
        [
          %w[id integer],
          %w[target_type varchar],
          %w[target_id integer],
          %w[title varchar],
          %w[data varchar],
          %w[project_id integer],
          %w[created_at timestamp],
          %w[updated_at timestamp],
          %w[action integer],
          %w[author_id integer]
        ]
      end

      it 'returns false' do
        expect(new_table).not_to be_column_order_optimized
      end
    end

    context 'when the column order is optimized' do
      let(:columns) do
        [
          %w[updated_at timestamp],
          %w[created_at timestamp],
          %w[author_id integer],
          %w[target_id integer],
          %w[project_id integer],
          %w[action integer],
          %w[id integer],
          %w[data varchar],
          %w[target_type varchar],
          %w[title varchar]
        ]
      end

      it 'returns true' do
        expect(new_table).to be_column_order_optimized
      end
    end
  end
end
