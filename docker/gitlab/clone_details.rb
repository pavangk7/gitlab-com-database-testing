#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

DBLAB_SSH_JSON_PORT=8000.freeze
DBLAB_SSH_JSON_FILE='/info.json'.freeze

def dblab_ssh_host
  ARGV[0]
end

def get_clone_details
  uri = URI("http://#{dblab_ssh_host}:#{DBLAB_SSH_JSON_PORT}/#{DBLAB_SSH_JSON_FILE}")
  response = Net::HTTP.get(uri)
  JSON(response)
end

clone_details = get_clone_details

clone_details['expectedRemovalTime'] = Time.now + 60 * clone_details['maxIdleMinutes']

puts clone_details.to_json
