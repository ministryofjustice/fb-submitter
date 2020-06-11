describe WebhookAttachmentService do
  subject(:service) { described_class.new(attachment_parser: attachment_parser, user_file_store_gateway: user_file_store_gateway) }

  before do
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_1).and_return(user_file_store_gateway_return[0])
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_2).and_return(user_file_store_gateway_return[1])
    allow(attachment_parser).to receive(:execute).and_return(attachments)
  end

  let(:user_file_store_gateway) { instance_spy(Adapters::UserFileStore) }
  let(:attachment_parser) { instance_spy(AttachmentParserService) }
  let(:attachment_1) { 'https://example.com/private_url_1' }
  let(:attachment_2) { 'https://example.com/private_url_2' }

  let(:attachments) do
    [
      build(:attachment, url: attachment_1, mimetype: 'application/pdf', filename: 'form1'),
      build(:attachment, url: attachment_2, mimetype: 'application/json', filename: 'afile')
    ]
  end

  let(:user_file_store_gateway_return) do
    [
      {
        url: 'example.com/public_url_1',
        encryption_key: 'somekey_1',
        encryption_iv: 'somekey_iv_1'
      },
      {
        url: 'example.com/public_url_2',
        encryption_key: 'somekey_2',
        encryption_iv: 'somekey_iv_2'
      }
    ]
  end

  let(:expected_attachments) do
    [
      {
        url: 'example.com/public_url_1',
        encryption_key: 'somekey_1',
        encryption_iv: 'somekey_iv_1',
        mimetype: 'application/pdf',
        filename: 'form1.pdf'
      },
      {
        url: 'example.com/public_url_2',
        encryption_key: 'somekey_2',
        encryption_iv: 'somekey_iv_2',
        mimetype: 'application/json',
        filename: 'afile.json'
      }
    ]
  end

  describe '#execute' do
    it 'returns a url and key hash' do
      expect(service.execute).to eq(expected_attachments)
    end

    it 'calls parser to get attachements' do
      service.execute
      expect(attachment_parser).to have_received(:execute).once
    end

    it 'calls the gateway for each attachment url' do
      service.execute
      expect(user_file_store_gateway).to have_received(:get_presigned_url).with(attachment_1).once
      expect(user_file_store_gateway).to have_received(:get_presigned_url).with(attachment_2).once
    end

    context 'when attachments are empty' do
      before do
        allow(attachment_parser).to receive(:execute).and_return([])
      end

      it 'returns empty array when given one' do
        expect(service.execute).to eq([])
      end
    end
  end
end
