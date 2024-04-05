require 'rails_helper'

RSpec.describe ServiceTokenService do
  subject do
    described_class.new(service_slug:, request_id:)
  end

  let(:service_slug) { 'some-service' }
  let(:request_id) { '12345' }
  let(:fake_client) { instance_double('Adapters::ServiceTokenCacheClient') }

  describe '#public_key' do
    before do
      allow(Adapters::ServiceTokenCacheClient).to receive(:new).with(request_id:).and_return(fake_client)
    end

    it 'returns public key' do
      allow(fake_client).to receive(:public_key_for).with('some-service').and_return('some-public-key')
      expect(subject.public_key).to eql('some-public-key')
    end
  end
end
