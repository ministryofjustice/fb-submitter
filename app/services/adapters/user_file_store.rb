module Adapters
  class UserFileStore
    class ClientRequestError < StandardError; end

    def initialize(key:)
      @key = key
    end

    def get_presigned_url(url)
      signed_url = "#{url}/presigned-s3-url"
      response = Typhoeus::Request.new(
        signed_url,
        headers: { 'x-encrypted-user-id-and-token': @key },
        method: :post
      ).run
      unless response.success?
        raise ClientRequestError, "Request for #{signed_url} returned response status of: #{response&.code}"
      end
      json = JSON.parse(response.body).symbolize_keys!
      {
        url: json.fetch(:url),
        key: json.fetch(:key)
      }
    end
  end
end
