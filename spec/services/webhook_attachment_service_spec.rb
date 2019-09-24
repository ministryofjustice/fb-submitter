describe WebhookAttachmentService do

  before do
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_1).and_return(expected_attachments[0])
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_2).and_return(expected_attachments[1])
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
      {url: 'example.com/public_url_1', encryption_key: 'somekey_1', encryption_iv: 'somekey_iv_1'},
      {url: 'example.com/public_url_2', encryption_key: 'somekey_2', encryption_iv: 'somekey_iv_2'}
    ]
  end

  describe '#execute' do
    it 'returns a url and key hash' do
      expect(service.execute).to eq(expected_attachments)
    end

    it 'calls the gateway for each attachment url' do
      service.execute
      expect(user_file_store_gateway).to have_received(:get_presigned_url).with(attachment_1).once
      expect(user_file_store_gateway).to have_received(:get_presigned_url).with(attachment_2).once
    end

    context 'when attachments are empty' do
      subject(:service) { described_class.new(attachments: [], user_file_store_gateway: user_file_store_gateway) }

      it 'returns empty array when given one' do
        expect(service.execute).to eq([])
      end
    end
  end
end
