source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

gem 'aws-sdk-sesv2', '~> 1.43'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'daemons'
gem 'delayed_job_active_record', '~> 4.1.10'
gem 'faraday', '~> 2.14.1'
gem 'fb-jwt-auth', '~> 0.10.0'
gem 'json-schema', '~> 5.0.0'
gem 'jwe', '~> 1.1.1'
gem 'jwt'
gem 'mime-types'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 6.4'
gem 'rails', '~> 7.2.3.1'
gem 'sentry-delayed_job', '~> 5.19.0'
gem 'sentry-rails', '~> 5.19.0'
gem 'sentry-ruby', '~> 5.19.0'
gem 'typhoeus'
gem 'tzinfo-data'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails', '~> 3.2.0'
  gem 'factory_bot_rails', '~> 6.5.0'
  gem 'listen'
  gem 'rspec-rails', '~> 8.0.0'
  gem 'rubocop'
  gem 'rubocop-govuk', '~> 5.2.0'
end

group :development do
  gem 'guard-rspec', '~> 4.7.3', require: false
  gem 'guard-shell', '~> 0.7.2'
end

group :test do
  gem 'database_cleaner-active_record', '~> 2.2.0'
  gem 'simplecov'
  gem 'simplecov-console', require: false
  gem 'webmock', '~> 3.24.0'
end
