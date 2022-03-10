# frozen_string_literal: true

require 'pry'
require_relative '../notifier'
require 'json'
require 'rspec-parameterized'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus unless ENV['CI'] == 'true'
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.disable_monkey_patching!
end

def file_fixture(path)
  File.join(Dir.pwd, 'spec', 'fixtures', path)
end

def override_env_from_fixture(path)
  JSON.parse(File.read(file_fixture(path))).each do |key, val|
    allow(Environment.instance).to receive(key.downcase).and_return(val)
  end
end

RSpec::Matchers.define :be_boolean do
  match do |actual|
    expect(actual).to be(true).or(be(false))
  end
end
