module Adapters
  class UserFileStore
    class ClientRequestError < StandardError; end

    attr_reader :key, :request_id

    def initialize(key:, request_id: nil)
      @key = key
      @request_id = request_id
    end

    def get_presigned_url(url)
      signed_url = "#{url}/presigned-s3-url"
      response = Typhoeus::Request.new(signed_url, headers:, method: :post).run

      raise ClientRequestError, "Request for #{signed_url} returned response status of: #{response&.code}" unless response.success?

      json = JSON.parse(response.body).symbolize_keys!
      {
        url: json.fetch(:url),
        encryption_key: json.fetch(:encryption_key),
        encryption_iv: json.fetch(:encryption_iv)
      }
    end

    private

    def headers
      {
        'x-encrypted-user-id-and-token' => key,
        'X-Request-Id' => request_id,
        'User-Agent' => 'Submitter'
      }
    end
  end
end
