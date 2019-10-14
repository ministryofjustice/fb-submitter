require 'rails_helper'
require 'webmock/rspec'

describe Adapters::PdfGenerator do
  subject(:adapter) do
    described_class.new(root_url: root_url, token: 'some-token')
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

  let(:root_url) do
    'http://www.pdf-generator.com/'
  end

  let(:expected_url) do
    'http://www.pdf-generator.com/v1/pdfs'
  end

  let(:expected_headers) do
    { 'x-access-token' => 'some-token' }
  end

  before do
    stub_request(:post, expected_url).to_return(status: 200, body: response, headers: {})
  end

  it 'requests a generated PDF' do
    adapter.generate_pdf(submission: submission)
    expect(WebMock).to have_requested(:post, expected_url).with(headers: expected_headers).once
  end

  it 'returns the pdf file from the response' do
    expect(adapter.generate_pdf(submission: submission)).to eq(response)
  end

  context 'when a 500 is returned' do
    before do
      stub_request(:post, expected_url).to_return(status: 500)
    end

    it 'throws an exception' do
      expect do
        adapter.generate_pdf(submission: {})
      end.to raise_error(Adapters::PdfGenerator::ClientRequestError)
    end
  end
end
