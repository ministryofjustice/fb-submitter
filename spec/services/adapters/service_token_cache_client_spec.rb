require 'rails_helper'
require 'ostruct'

RSpec.describe Adapters::ServiceTokenCacheClient do
  subject { described_class.new(request_id:) }

  let(:root_url) { 'http://fake_service_token_cache_root_url' }
  let(:service_slug) { 'service-slug' }
  let(:request_id) { '12345' }

  before do
    allow(ENV).to receive(:[]).with('SERVICE_TOKEN_CACHE_ROOT_URL').and_return(root_url)
  end

  describe '#public_key_for' do
    let(:uri) { URI('http://fake_service_token_cache_root_url/service/v2/service-slug') }
    let(:response) { OpenStruct.new(code: 200, body: "{\"token\":\"#{encoded_public_key}\"}") }
    let(:encoded_public_key) { 'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEzU1RCMkxnaDAyWWt0K0xxejluNgo5MlNwV0xFdXNUR1hEMGlmWTBuRHpmbXF4MWVlbHoxeHhwSk9MZXRyTGdxbjM3aE1qTlkwL25BQ2NNZHVFSDlLClhycmFieFhYVGwxeVkyMStnbVd4NDlOZVlESW5iZG0rNnM1S3ZMZ1VOTjdYVmNlUDlQdXFaeXN4Q1ZBNFRubUwKRURLZ2xTV2JVeWZ0QmVhVENKVkk2NFoxMmRNdFBiQWd4V0FmZVNMbGI3QlBsc0htL0gwQUFMK25iYU9Da3d2cgpQSkRMVFZPek9XSE1vR2dzMnJ4akJIRC9OV05ac1RWUWFvNFh3aGVidWRobHZNaWtFVzMyV0tnS3VISFc4emR2ClU4TWozM1RYK1picVhPaWtkRE54dHd2a1hGN0xBM1loOExJNUd5ZDlwNmYyN01mbGRnVUlIU3hjSnB5MUo4QVAKcXdJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==' }

    let(:expected_headers) do
      {
        'X-Request-Id' => request_id,
        'User-Agent' => 'Submitter'
      }
    end

    it 'returns public_key' do
      allow(Net::HTTP).to receive(:get_response).with(uri, expected_headers).and_return(response)
      public_key = subject.public_key_for(service_slug)
      expect(public_key).to match(/-----BEGIN PUBLIC KEY-----/)
      expect(public_key).to match(/-----END PUBLIC KEY-----/)
    end
  end
end
