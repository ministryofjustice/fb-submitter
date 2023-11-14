require 'rails_helper'
require 'webmock/rspec'

describe Adapters::PdfApi do
  subject(:adapter) do
    described_class.new(root_url:, token:, request_id:)
  end

  let(:submission) do
    {
      submission_id: 1,
      other_stuff: []
    }
  end

  let(:response) do
    'a-lot-of-pdf-contents'
  end

  let(:root_url) { 'http://www.pdf-generator.com/' }
  let(:token) { 'some-token' }
  let(:request_id) { '12345' }

  let(:expected_url) do
    'http://www.pdf-generator.com/v1/pdfs'
  end

  let(:expected_headers) do
    {
      'x-access-token-v2' => token,
      'X-Request-Id' => request_id,
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  before do
    stub_request(:post, expected_url).to_return(status: 200, body: response, headers: {})
  end

  it 'requests a generated PDF' do
    adapter.generate_pdf(submission:)
    expect(WebMock).to have_requested(:post, expected_url).with(headers: expected_headers).once
  end

  it 'returns the pdf file from the response' do
    expect(adapter.generate_pdf(submission:)).to eq(response)
  end

  context 'when a 500 is returned' do
    before do
      stub_request(:post, expected_url).to_return(status: 500)
    end

    it 'throws an exception' do
      expect {
        adapter.generate_pdf(submission: {})
      }.to raise_error(Adapters::PdfApi::ClientRequestError)
    end
  end
end
