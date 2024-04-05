require 'net/http'

module Adapters
  class ServiceTokenCacheClient
    attr_reader :root_url, :request_id

    def initialize(params = {})
      @root_url = params[:root_url] || ENV['SERVICE_TOKEN_CACHE_ROOT_URL']
      @request_id = params[:request_id]
    end

    def public_key_for(service_slug)
      url = public_key_uri(service_slug)
      response = Net::HTTP.get_response(url, headers)

      return unless response.code.to_i == 200

      Base64.strict_decode64(JSON.parse(response.body).fetch('token'))
    end

    private

    def headers
      {
        'X-Request-Id' => request_id,
        'User-Agent' => 'Submitter'
      }
    end

    def public_key_uri(service_slug)
      URI.join(root_url, '/service/v2/', service_slug)
    end
  end
end
