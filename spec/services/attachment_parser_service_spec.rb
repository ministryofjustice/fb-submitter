require 'rails_helper'

describe AttachmentParserService do
  context 'when given no input' do
    subject(:service) { described_class.new(attachments: []) }

    it 'returns a empty array' do
      expect(service.execute).to eq([])
    end
  end

  context 'when given a single attachment' do
    subject(:service) { described_class.new(attachments: input) }

    let(:input) do
      [
        {
          type: 'output',
          mimetype: 'applcation/pdf',
          filename: 'foo.pdf',
          url: 'https://example.com'
        }
      ]
    end

    it 'returns a list of attachment objects' do
      expect(service.execute.count).to eq(1)
      expect(service.execute.first).to have_attributes(class: Attachment, type: 'output', mimetype: 'applcation/pdf', filename: 'foo.pdf', url: 'https://example.com', path: nil)
    end
  end
end
