module Adapters
  class UserFileStore
    class ClientRequestError < StandardError; end

    def initialize(key:)
      @key = key
    end

    def get_presigned_url(url)
      public_url = "#{url}/public-file"
      response = Typhoeus::Request.new(
        public_url,
        headers: {'x-encrypted-user-id-and-token': @key},
        method: :post,
        # body: body
      ).run
      unless response.success?
        raise ClientRequestError, "Request for #{public_url} returned response status of: #{response&.code}"
      end
    end
  end
end
