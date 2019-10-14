source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

gem 'aws-sdk-ses', '~> 1.26.0'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'daemons'
gem 'delayed_job_active_record', '~> 4.1.4'
gem 'jwe', '~> 0.4.0'
gem 'jwt'
gem 'mime-types'
gem 'notifications-ruby-client'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.2'
gem 'rails', '~> 5.2.3'
gem 'sentry-raven'
gem 'typhoeus'
gem 'tzinfo-data'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '>= 3.8.0'
  gem 'rswag-specs'
  gem 'rubocop', '~> 0.75.0'
  gem 'rubocop-rspec', '~> 1.35'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'guard-shell'
  gem 'listen',
  gem 'rswag-api'
  gem 'rswag-ui'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails', '~> 5.1'
  gem 'simplecov'
  gem 'simplecov-console', require: false
  gem 'timecop'
  gem 'webmock'
end
