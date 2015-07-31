source 'https://rubygems.org'

gem 'rails', '~> 4.2.3'
gem 'rack-cors', '~> 0.4.0'
gem 'pg', '~> 0.18.2'
gem 'redis', '~> 3.2.1'
gem 'sidekiq', '~> 3.4.1'
gem 'sidekiq-congestion'
gem 'sidetiq', '~> 0.6.3'
gem 'sinatra', '~> 1.4'
gem 'restpack_serializer', github: 'parrish/restpack_serializer', branch: 'dev', ref: '05331630f3'
gem 'json-schema', '~> 2.5.0'
gem 'json-schema_builder', '~> 0.0.7'
gem 'aws-sdk', '~> 2.1.7'
gem 'faraday', '~> 0.9.1'
gem 'faraday_middleware', '~> 0.10.0'
gem 'faraday-http-cache', '~> 1.1.0'
gem 'pundit', '~> 1.0.1'
gem 'sdoc', '~> 0.4', group: :doc
gem 'spring', group: :development
gem 'newrelic_rpm', '~> 3.12'
gem 'honeybadger', '~> 2.1.1'

group :production do
  gem 'puma', '~> 2.12.2'
end

group :test, :development do
  gem 'rspec-rails', '~> 3.3.3'
  gem 'rspec-its', '~> 1.2.0'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'guard-rspec', '~> 4.6.3'
  gem 'timecop'
  gem 'pry', '~> 0.10.1'
end

group :test do
  gem 'codeclimate-test-reporter', '~> 0.4.7'
  gem 'simplecov', '~> 0.10.0'
end
