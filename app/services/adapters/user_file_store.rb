module Adapters
  class UserFileStore

    def initialize(key:)
      @key = key
    end

    def get_presigned_url(url)
      public_url = "#{url}/public-file"
      Typhoeus::Request.new(
        public_url,
        headers: {'x-encrypted-user-id-and-token': @key},
        method: :post,
        # body: body
      ).run
      # unless response.success?
      #   raise ClientRequestError, "request for #{url} returned response status of: #{response.code}"
      # end todo
    end
  end
end
