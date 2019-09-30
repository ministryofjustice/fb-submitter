require 'rails_helper'
require 'webmock/rspec'

describe Adapters::RunnerCallback do
  subject do
    described_class.new(url: expected_url, token: 'some-token')
  end

  let(:response) do
    { id: SecureRandom.uuid }.to_json
  end

  let(:expected_url) do
    "http://www.example.com/#{SecureRandom.uuid}"
  end

  let(:expected_headers) do
    { 'x-encrypted-user-id-and-token' => 'some-token' }
  end

  before do
    stub_request(:get, expected_url).to_return(status: 200, body: response, headers: {})
  end

  it 'calls callback' do
    subject.fetch_full_submission
    expect(WebMock).to have_requested(:get, expected_url).with(headers: expected_headers).once
  end

  it 'returns the submission json when given a url' do
    expect(subject.fetch_full_submission).to eq(response)
  end

  context 'when a 500 is returned' do
    before do
      stub_request(:get, expected_url).to_return(status: 500)
    end

    it 'throws an exception' do
      expect do
        subject.fetch_full_submission
      end.to raise_error(Adapters::RunnerCallback::ClientRequestError)
    end
  end
end
