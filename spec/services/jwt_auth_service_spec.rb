require 'rails_helper'

RSpec.describe JwtAuthService do
  subject(:service) { described_class.new(service_token_cache: service_token_cache, service_slug: service_slug) }

  before do
    allow(service_token_cache).to receive(:get).and_return(shared_secret)
  end

  let(:service_token_cache) { instance_spy(Adapters::ServiceTokenCacheClient) }

  let(:service_slug) { SecureRandom.alphanumeric(10) }
  let(:shared_secret) { SecureRandom.alphanumeric(10) }

  it 'gets the shared secret using the service_slug' do
    service.execute
    expect(service_token_cache).to have_received(:get).once
  end

  it 'returns valid token' do
    expect do
      JWT.decode(service.execute, shared_secret, verify = true, algorithm: 'HS256') # rubocop:disable Lint/UselessAssignment
    end.not_to raise_error
  end

  it 'returns a token with iss header as the given service slug' do
    _data, headers = JWT.decode(service.execute, shared_secret, verify = false, algorithm: 'HS256') # rubocop:disable Lint/UselessAssignment
    expect(headers.symbolize_keys).to eq(
      alg: 'HS256',
      iss: service_slug
    )
  end
end
