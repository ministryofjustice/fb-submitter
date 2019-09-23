# frozen_string_literal: true

describe PublicAttachmentService do

  before do
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_1).and_return({:key=>"somekey_1", :url=>"example.com/public_url_1"})
    allow(user_file_store_gateway).to receive(:get_presigned_url).with(attachment_2).and_return({:key=>"somekey_2", :url=>"example.com/public_url_2"})
  end

  let(:user_file_store_gateway) { instance_spy(Adapters::UserFileStore) }

  subject(:service) { described_class.new(user_file_store_gateway: user_file_store_gateway) }

  let(:attachment_1) { 'https://example.com/private_url_1'}
  let(:attachment_2) { 'https://example.com/private_url_2'}

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
      expect(service.execute([attachment_1, attachment_2])).to eq(expected_attachments)
    end

    it 'calls the gateway for each object' do
      service.execute([attachment_1, attachment_2])
      expect(user_file_store_gateway).to have_received(:get_presigned_url).twice
    end

    it 'returns empty arry when given one' do
      expect(service.execute([])).to eq([])
    end
  end
end
