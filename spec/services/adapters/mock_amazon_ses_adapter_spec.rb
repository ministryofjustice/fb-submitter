require 'rails_helper'

describe Adapters::MockAmazonSESAdapter do
  subject(:mock) { described_class }

  let(:http_client_class) { Typhoeus }

  describe '.send_email' do
    let(:endpoint) { 'http://endpoint_override' }
    let(:body) { { foo: 'bar' } }

    before do
      allow(ENV).to receive(:fetch).with('EMAIL_ENDPOINT_OVERRIDE').and_return(endpoint)
      allow(http_client_class).to receive(:post)
    end

    it 'performs the POST with the expected endpoint and body' do
      mock.send_mail(body)

      expect(
        http_client_class
      ).to have_received(:post).with(endpoint, body:)
    end
  end
end
