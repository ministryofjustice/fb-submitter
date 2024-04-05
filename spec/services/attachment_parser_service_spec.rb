require 'rails_helper'

describe AttachmentParserService do
  subject(:service) { described_class.new(attachments:) }

  context 'when given no input' do
    let(:attachments) { [] }

    it 'returns a empty array' do
      expect(service.execute).to eq([])
    end
  end

  context 'when given a single attachment' do
    context 'when all attachments are successfully parsed' do
      let(:attachments) do
        [
          {
            'type' => 'output',
            'mimetype' => 'application/pdf',
            'filename' => 'foo.pdf',
            'url' => 'https://example.com',
            'pdf_data' => {
              question: 'answer'
            }
          }
        ]
      end

      it 'returns 1 object in array' do
        expect(service.execute.count).to eq(1)
      end

      it 'returns a list of attachment objects' do
        expect(service.execute.first).to have_attributes(class: Attachment, type: 'output', mimetype: 'application/pdf', filename: 'foo.pdf', url: 'https://example.com', path: nil)
      end
    end

    context 'when some attachment fails to parse' do
      let(:attachments) do
        [
          {
            # This attachment is missing required `mimetype` attribute, so will fail
            'type' => 'output',
            'filename' => 'foo1.pdf',
            'url' => 'https://example.com',
            'pdf_data' => {
              question: 'answer'
            }
          },
          {
            'type' => 'output',
            'mimetype' => 'application/pdf',
            'filename' => 'foo2.pdf',
            'url' => 'https://example.com',
            'pdf_data' => {
              question: 'answer'
            }
          }
        ]
      end

      it 'returns only objects successfully parsed' do
        expect(service.execute.count).to eq(1)
      end

      it 'returns a list of attachment objects' do
        expect(service.execute.first).to have_attributes(filename: 'foo2.pdf')
      end
    end
  end
end
