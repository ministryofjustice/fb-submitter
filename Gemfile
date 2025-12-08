source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

gem 'aws-sdk-sesv2', '~> 1.43'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'daemons'
gem 'delayed_job_active_record', '~> 4.1.7'
gem 'faraday', '~> 2.0'
gem 'fb-jwt-auth', '~> 0.10.0'
gem 'json-schema', '~> 4.1.1'
gem 'jwe', '~> 1.1.1'
gem 'jwt'
gem 'mime-types'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 6.4'
gem 'rails', '~> 7.1.5.2'
gem 'sentry-delayed_job', '~> 5.14'
gem 'sentry-rails', '~> 5.14'
gem 'sentry-ruby', '~> 5.14'
gem 'typhoeus'
gem 'tzinfo-data'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-govuk'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'guard-shell'
  gem 'listen'
end

group :test do
  gem 'database_cleaner-active_record', '~> 2.1.0'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'simplecov'
  gem 'simplecov-console', require: false
  gem 'webmock'
end
