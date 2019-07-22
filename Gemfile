source 'https://rubygems.org'

ruby File.read(".ruby-version").strip

gem 'rails', '~> 5.2.3'
gem 'pg', '1.1.4'
gem 'puma', '4.0.1'
gem 'aws-sdk-ses', '1.24.0'
gem 'jwt'
gem 'resque'
gem 'sidekiq'
gem 'typhoeus'
gem 'mime-types'
gem 'notifications-ruby-client'
gem 'sentry-raven'
gem 'tzinfo-data'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara', '>= 2.15', '< 4.0'
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
  gem 'factory_bot_rails', '~> 4.0'
  gem 'faker'
  gem 'poltergeist'
  gem 'phantomjs'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'simplecov'
  gem 'simplecov-console', require: false
  gem 'webmock'
  gem 'timecop'
end
