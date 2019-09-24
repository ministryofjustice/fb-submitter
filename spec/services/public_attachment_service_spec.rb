describe PublicAttachmentService do

  before do
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_1).and_return({:key=>"somekey_1", :url=>"example.com/public_url_1"})
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_2).and_return({:key=>"somekey_2", :url=>"example.com/public_url_2"})
  end

  let(:user_file_store_gateway) { instance_spy(Adapters::UserFileStore) }

  subject(:service) { described_class.new(attachments: attachments, user_file_store_gateway: user_file_store_gateway) }

  let(:attachment_1) { 'https://example.com/private_url_1'}
  let(:attachment_2) { 'https://example.com/private_url_2'}

  let(:attachments) do
    [
      {
        'type': 'output',
        'mimetype': 'application/pdf',
        'url': attachment_1,
        'filename': 'form1'
      },
      {
        'type': 'output',
        'mimetype': 'application/pdf',
        'url': attachment_2,
        'filename': 'form2'
      }
    ]
  end

  let(:expected_attachments) do
    [
      {
        url: 'example.com/public_url_1',
        key: 'somekey_1'
      },
      {
        url: 'example.com/public_url_2',
        key: 'somekey_2'
      }
    ]
  end

  describe '#execute' do
    it 'returns a url and key hash' do
      expect(service.execute).to eq(expected_attachments)
    end

    it 'calls the gateway for each object' do
      service.execute
      expect(user_file_store_gateway).to have_received(:get_presigned_url).twice
    end

    context 'when attachments are empty' do
      subject(:service) { described_class.new(attachments: [], user_file_store_gateway: user_file_store_gateway) }

      it 'returns empty arry when given one' do
        expect(service.execute).to eq([])
      end
    end
  end
end
