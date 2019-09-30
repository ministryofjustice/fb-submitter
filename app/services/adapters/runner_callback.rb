module Adapters
  class RunnerCallback
    class ClientRequestError < StandardError
    end

    def initialize(url:, token:)
      @url = url
      @token = token
    end

    def fetch_full_submission
      response = Typhoeus.get(url, headers: headers)

      unless response.success?
        raise ClientRequestError, "request for #{url} returned response status of: #{response.code}"
      end

      response.body
    end

    private

    def headers
      { 'x-encrypted-user-id-and-token' => token }
    end

    attr_reader :url, :token
  end
end
