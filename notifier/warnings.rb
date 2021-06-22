# frozen_string_literal: true

class Warnings
  attr_reader :all

  def initialize(result)
    @all = result.migrations_from_branch.select(&:warning?).map(&:warnings).flatten
  end

  def count
    @all.count
  end

  def any?
    @all.any?
  end

  def with_line_breaks
    all.map do |warning|
      warning.split(' ').reduce('') do |final, word|
        if word.sub(/]\(.*\)/, '').length + (final.split('<br />').last&.sub(/]\(.*\)/, '')&.length || 0) > 100
          final = "#{final}<br />"
        end

        "#{final} #{word}"
      end
    end
  end

  def render
    return '' unless any?

    ERB.new(File.read("templates/warnings.erb"), trim_mode: '<>%').result(binding)
  end
end
