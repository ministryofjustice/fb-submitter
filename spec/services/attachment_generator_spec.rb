require 'rails_helper'
require_relative '../../app/services/attachment_generator'

describe AttachmentGenerator do
  subject(:generator) { described_class.new }

  let(:upload1) { build(:attachment) }
  let(:upload2) { build(:attachment) }
  let(:upload3) { build(:attachment) }
  let(:upload4) { build(:attachment) }
  let(:upload5) { build(:attachment) }
  let(:upload6) { build(:attachment) }
  let(:pdf_attachment) { build(:attachment, mimetype: 'application/pdf', url: nil) }

  before do
    allow(upload1).to receive(:size).and_return(5678)
    allow(upload2).to receive(:size).and_return(1234)
    allow(upload3).to receive(:size).and_return(8_999_999)
    allow(upload4).to receive(:size).and_return(44_444)
    allow(upload5).to receive(:size).and_return(111)
    allow(upload6).to receive(:size).and_return(8_999_999)
    allow(pdf_attachment).to receive(:size).and_return(7777)
  end

  # rubocop:disable RSpec/ExampleLength
  context 'when no attachments or pdfs are required' do
    it 'does not sort any attachments' do
      subject.execute(action: {}, attachments: [upload1, upload2], pdf_attachment:)
      expect(subject.sorted_attachments).to be_empty
    end
  end

  context 'when included attachments are required' do
    it 'sorts the files by size, smallest first' do
      subject.execute(
        action: { include_attachments: true },
        attachments: [upload1, upload2],
        pdf_attachment: nil
      )

      expect(subject.sorted_attachments).to eq([[upload2, upload1]])
    end

    it 'splits files into separate email payloads when above the maximum limit' do
      subject.execute(
        action: { include_attachments: true },
        attachments: [upload1, upload3],
        pdf_attachment: nil
      )

      expect(subject.sorted_attachments).to eq(
        [
          [upload1],
          [upload3]
        ]
      )
    end
  end

  context 'when pdf attachment is required' do
    it 'sorts only the pdf attachment' do
      allow(pdf_attachment).to receive(:size).and_return(7777)
      subject.execute(
        action: { include_pdf: true },
        attachments: nil,
        pdf_attachment:
      )

      expect(subject.sorted_attachments).to eq([[pdf_attachment]])
    end
  end

  context 'when both attachments and pdf submission are required' do
    it 'puts pdf submission first and remaining attachments by size' do
      subject.execute(
        action: { include_attachments: true, include_pdf: true },
        attachments: [upload1, upload2],
        pdf_attachment:
      )

      expect(subject.sorted_attachments).to eq([[pdf_attachment, upload2, upload1]])
    end

    it 'splits all files over multiple email payloads when the maximum limit is reached' do
      subject.execute(
        action: { include_attachments: true, include_pdf: true },
        attachments: [upload1, upload2, upload3, upload4, upload5, upload6],
        pdf_attachment:
      )

      expect(subject.sorted_attachments).to eq(
        [
          [pdf_attachment, upload5, upload2, upload1, upload4],
          [upload3],
          [upload6]
        ]
      )
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
