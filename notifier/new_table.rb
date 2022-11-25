# frozen_string_literal: true

class NewTable
  DATA_TYPE_POSITION = 1
  VARIABLE_SIZE_TYPE_LENGTH = -1
  FILE_NAME = 'pg_data_types.yml'

  def initialize(columns)
    @columns = columns
  end

  def optimize_column_order
    columns.sort do |a, b|
      data_type_length(b[DATA_TYPE_POSITION]) <=> data_type_length(a[DATA_TYPE_POSITION])
    end
  end

  def column_order_optimized?
    bytes_sorted(columns) == bytes_sorted(optimize_column_order)
  end

  private

  attr_accessor :columns

  def bytes_sorted(columns)
    columns.map { |column| pg_data_types[column[DATA_TYPE_POSITION]] }
  end

  def pg_data_types
    @pg_data_types ||= YAML.load_file(FILE_NAME)
  end

  def data_type_length(data_type)
    pg_data_types[data_type] || VARIABLE_SIZE_TYPE_LENGTH
  end
end
