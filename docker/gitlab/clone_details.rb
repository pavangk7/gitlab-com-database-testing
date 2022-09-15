#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'yaml'

DBLAB_SSH_JSON_PORT=8000.freeze
DBLAB_SSH_JSON_FILE='/info.json'.freeze
CLONE_DETAILS_CONFIG_FILE='clone_details.yml'.freeze

def load_configuration
  YAML.load(File.read(CLONE_DETAILS_CONFIG_FILE))
end

def add_clone_info(response, clone)
  response['expectedRemovalTime'] = Time.now + 60 * response['maxIdleMinutes']
  response['projectName'] = clone['project-name']
  response['instanceId'] = clone['instance-id']
  response
end

def get_clone_details(config)
  config['clones'].map do |clone|
    uri = URI("http://#{clone['host']}:#{DBLAB_SSH_JSON_PORT}/#{DBLAB_SSH_JSON_FILE}")
    response = JSON(Net::HTTP.get(uri))
    add_clone_info(response, clone)
  end
end

puts get_clone_details(load_configuration).to_json
