module Adapters
  class PdfGenerator
    class ClientRequestError < StandardError
    end
    def initialize(url:, token:)
      @url = url
      @token = token
    end

    def generate_pdf(submission:)
      response = Typhoeus.post(url, body: submission.to_json, headers: headers)

      raise ClientRequestError, "request for #{url} returned response status of: #{response.code}" unless response.success?

      response.body
    end

    private

    def headers
      { 'x-access-token' => token }
    end

    attr_reader :url, :token
  end
end