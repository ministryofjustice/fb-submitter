require 'rails_helper'
require 'webmock/rspec'
require 'jwe'

describe Adapters::JweWebhookDestination do
  subject(:adapter) do
    described_class.new(url: expected_url, key: key)
  end

  let(:payload) do
    { id: SecureRandom.uuid }
  end

  let(:key) { '056a757e37f69950' }

  let(:expected_url) do
    "http://www.example.com/#{SecureRandom.uuid}"
  end

  let(:response) { instance_double(Typhoeus::Response) }
  let(:request) { instance_double(Typhoeus::Request, run: response) }

  before do
    allow(response).to receive(:success?).and_return(true)
  end

  it 'makes a post to the given url' do
    stub_request(:post, expected_url).to_return(status: 200)

    adapter.send_webhook(body: payload)

    expect(WebMock).to have_requested(:post, expected_url).once
  end

  # rubocop:disable RSpec/ExampleLength
  it 'sends JWE encrypted payload' do
    allow(Typhoeus::Request).to receive(:new) do |url, hash|
      expect(url).to eql(expected_url)
      expect(hash[:method]).to be(:post)
      expect(JSON.parse(JWE.decrypt(hash[:body], key)).symbolize_keys).to eql(payload)
    end.and_return(request)

    adapter.send_webhook(body: payload)
  end
  # rubocop:enable RSpec/ExampleLength

  it 'throws exception if not 200 response' do
    stub_request(:post, expected_url).to_return(status: 500)

    expect do
      adapter.send_webhook(body: payload)
    end.to raise_error(Adapters::JweWebhookDestination::ClientRequestError)
  end
end
