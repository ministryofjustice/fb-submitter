require 'net/http'

module Adapters
  class ServiceTokenCacheClient
    attr_accessor :root_url

    def initialize(params = {})
      @root_url = params[:root_url] || ENV['SERVICE_TOKEN_CACHE_ROOT_URL']
    end

    def get(service_slug)
      url = service_token_uri(service_slug)
      response = Net::HTTP.get_response(url)
      JSON.parse(response.body).fetch('token') if response.code.to_i == 200
    end

    def service_token_uri(service_slug)
      URI.join(@root_url, '/service/', service_slug)
    end
  end
end
