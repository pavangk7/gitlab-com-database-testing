# frozen_string_literal: true

class Warnings
  attr_reader :all

  def initialize(result)
    @all = result.migrations.values.select(&:warning?).map(&:warnings).flatten
  end

  def count
    @all.count
  end

  def any?
    @all.any?
  end

  def render
    return '' unless any?

    ERB.new(File.read("templates/warnings.erb"), trim_mode: '<>%').result(binding)
  end
end
