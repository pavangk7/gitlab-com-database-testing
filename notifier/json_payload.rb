# frozen_string_literal: true
require 'json'
require "base64"

class JsonPayload
  VERSION = 1

  ATTRIBUTES = %w[migration walltime total_database_size_change success].freeze

  def encode(result)
    data = result.migrations_from_branch.map do |migration|
      # We only expose a subset of the statistics available here
      migration.statistics.to_h.slice(*ATTRIBUTES)
    end

    json = {
      # The version should change when the JSON schema significantly changes.
      # This will allow readers to know how to read data later
      version: VERSION,
      data: data
    }.to_json

    Base64.encode64(json)
  end
end
