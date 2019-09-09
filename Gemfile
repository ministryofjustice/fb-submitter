source 'https://rubygems.org'

ruby File.read(".ruby-version").strip

gem 'bootsnap', '>= 1.1.0', require: false
gem 'rails', '~> 5.2.3'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'aws-sdk-ses', '~> 1.25.0'
gem 'jwt'
gem 'typhoeus'
gem 'daemons'
gem 'delayed_job_active_record', '~> 4.1.3'
gem 'mime-types'
gem 'notifications-ruby-client'
gem 'sentry-raven'
gem 'tzinfo-data'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '>= 3.8.0'
  gem 'rswag-specs'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'guard-rspec', require: false
  gem 'rswag-api'
  gem 'rswag-ui'
  gem 'guard-shell'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails', '~> 5.0'
  gem 'simplecov'
  gem 'simplecov-console', require: false
  gem 'webmock'
  gem 'timecop'
end
