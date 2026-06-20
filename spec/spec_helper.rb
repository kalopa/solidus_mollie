# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

# Uncomment to generate coverage reports (must be at the very top):
# require 'solidus_dev_support/rspec/coverage'

# Create the dummy app if it's still missing, then load it.
dummy_env = "#{__dir__}/dummy/config/environment.rb"
system 'bin/rake extension:test_app' unless File.exist?(dummy_env)
require dummy_env

# Solidus + Rails RSpec configuration, factories, feature helpers, etc.
require 'solidus_dev_support/rspec/feature_helper'

# This extension's own factories.
require 'solidus_mollie/factories'

# Support files (custom matchers, shared contexts, the Mollie stub helper).
Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.example_status_persistence_file_path = "#{__dir__}/examples.txt"

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  Kernel.srand config.seed
end
