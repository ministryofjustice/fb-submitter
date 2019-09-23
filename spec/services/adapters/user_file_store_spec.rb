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

  xit 'the post has the desired_url in the body' do
    adaptor.get_presigned_url(url)
    expect(WebMock).to have_requested(:post, requested_url).once
  end
end
