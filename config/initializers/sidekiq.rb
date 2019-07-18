return if ENV['RAILS_ENV'] == 'test'

url = (ENV['REDISCLOUD_URL'] || ENV['REDIS_URL'])
uri_with_protocol = (ENV['REDIS_PROTOCOL'] || 'redis://') + url.to_s
uri = URI.parse(uri_with_protocol)

Sidekiq.configure_server do |config|
  config.redis = {
    url: uri_with_protocol,
    password: ENV['REDIS_AUTH_TOKEN']
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: uri_with_protocol,
    password: ENV['REDIS_AUTH_TOKEN']
  }
end
