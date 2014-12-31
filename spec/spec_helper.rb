ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'codeclimate-test-reporter'
SimpleCov.configure do
  add_filter '/spec'
  add_filter '/config/initializers'
end

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
  ]
end

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'json/schema_builder/rspec'
require 'webmock/rspec'
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include JSON::SchemaBuilder::RSpecHelper, type: :schema
  
  config.before(:suite){ WebMock.disable_net_connect! }
  config.after(:suite){ WebMock.allow_net_connect! }
  
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end
