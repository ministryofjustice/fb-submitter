describe Adapters::UserFileStore do

  subject(:adaptor) { described_class.new(key: key) }

  before do
    stub_request(:post, requested_url)
  end

  let(:url) { "https://the-url/#{SecureRandom.alphanumeric(10)}" }
  let(:key) { SecureRandom.alphanumeric(10) }

  let(:requested_url) { "#{url}/public-file" }

  it 'posts to the user file store endpoint' do
    adaptor.get_presigned_url(url)
    expect(WebMock).to have_requested(:post, requested_url).once
  end

  it 'posts the required headers in the request' do
    adaptor.get_presigned_url(url)
    expect(WebMock).to have_requested(:post, requested_url).with(headers: {
      'x-encrypted-user-id-and-token': key,
      'Expect': '',
      'User-Agent': 'Typhoeus - https://github.com/typhoeus/typhoeus'
    })
  end

  context 'when there is a failing responce' do

    before do
      stub_request(:post, requested_url).to_return(status: 400)
    end

    it 'throws an exception' do
      expect {
        adaptor.get_presigned_url(url)
      }.to raise_error(Adapters::UserFileStore::ClientRequestError).with_message("Request for #{requested_url} returned response status of: 400")
    end
  end
end
