#!/usr/bin/env ruby
# frozen_string_literal: true
require 'pry'
require 'json'
require './lib/migration_lister'

lister = MigrationLister.new

puts lister.migrations.to_json
