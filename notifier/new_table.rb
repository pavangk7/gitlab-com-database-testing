# frozen_string_literal: true

class NewTable
  DATA_TYPE_POSITION = 1
  VARIABLE_SIZE = -1

  def initialize(columns)
    @columns = columns
  end

  def optimize_column_order
    columns.sort { |a,b| pg_data_types[b[DATA_TYPE_POSITION]] <=> pg_data_types[a[DATA_TYPE_POSITION]] }
  end

  def is_column_order_optimized?
    bytes_sorted(columns) == bytes_sorted(optimize_column_order)
  end

  private

  attr_accessor :columns

  def bytes_sorted(columns)
    columns.map { |column| pg_data_types[column[DATA_TYPE_POSITION]] }
  end

  def pg_data_types
    {
      "smallint" => 2,
      "integer" => 4,
      "bigint" => 8,
      "timestamp" => 8,
      "varchar" => VARIABLE_SIZE,
      "text" => VARIABLE_SIZE,
      "boolean" => 1
    }
  end
end
