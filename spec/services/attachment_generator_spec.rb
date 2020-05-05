require 'rails_helper'
require_relative '../../app/services/attachment_generator'

describe AttachmentGenerator do
  subject(:generator) { described_class.new }

  let(:download_service) { double() }

  let(:upload1) { JSON.parse(build(:attachment).to_json) }
  let(:upload2) { JSON.parse(build(:attachment).to_json) }
  let(:upload3) { JSON.parse(build(:attachment).to_json) }
  let(:upload4) { JSON.parse(build(:attachment).to_json) }
  let(:upload5) { JSON.parse(build(:attachment).to_json) }
  let(:upload6) { JSON.parse(build(:attachment).to_json) }
  let(:pdf_attachment) { build(:attachment, mimetype: 'application/pdf', url: nil) }

  before do
    allow(download_service).to receive(:get_file_size).with(upload1['url']).and_return(5678)
    allow(download_service).to receive(:get_file_size).with(upload2['url']).and_return(1234)
    allow(download_service).to receive(:get_file_size).with(upload3['url']).and_return(8_999_999)
    allow(download_service).to receive(:get_file_size).with(upload4['url']).and_return(44_444)
    allow(download_service).to receive(:get_file_size).with(upload5['url']).and_return(111)
    allow(download_service).to receive(:get_file_size).with(upload6['url']).and_return(8_999_999)
    allow(pdf_attachment).to receive(:size).and_return(7777)
  end

  # rubocop:disable RSpec/ExampleLength
  context 'when no attachments or pdfs are required' do
    subject do
      described_class.new(
        action: {},
        download_service: download_service,
        payload_attachments: [upload1, upload2],
        pdf_attachment: pdf_attachment
      )
    end

    it 'will not sort any attachments' do
      expect(subject.grouped_attachments).to be_empty
    end
  end

  context 'when included attachments are required' do
    subject do
      described_class.new(
        action: { include_attachments: true },
        download_service: download_service,
        payload_attachments: [upload1, upload2, upload3],
        pdf_attachment: pdf_attachment
      )
    end

    let(:grouped_attachments) { subject.grouped_attachments }

    it 'generates attachment classes for each upload' do
      grouped_attachments.flatten.each do |attachment|
        expect(attachment).to be_a_kind_of(Attachment)
      end
    end

    it 'splits files into separate email payloads when above the maximum limit ordered by size' do
      expect(grouped_attachments.count).to be(2)
      expect(grouped_attachments.first.map(&:filename)).to eq([upload2['filename'], upload1['filename']])
      expect(grouped_attachments.last.map(&:filename)).to eq([upload3['filename']])
    end
  end

  context 'when pdf attachment is required' do
    subject do
      described_class.new(
        action: { include_pdf: true },
        download_service: download_service,
        payload_attachments: [],
        pdf_attachment: pdf_attachment
      )
    end

    it 'will sort only the pdf attachment' do
      expect(subject.grouped_attachments).to eq([[pdf_attachment]])
    end
  end

  context 'when both attachments and pdf submission are required' do
    subject do
      described_class.new(
        action: { include_attachments: true, include_pdf: true },
        download_service: download_service,
        payload_attachments: [upload1, upload2, upload3, upload4, upload5, upload6],
        pdf_attachment: pdf_attachment
      )
    end

    let(:grouped_attachments) { subject.grouped_attachments }

    it 'puts pdf submission first' do
      expect(grouped_attachments.first.first).to eq(pdf_attachment)
    end

    it 'will split all files over multiple email payloads when the maximum limit is reached' do
      expect(grouped_attachments.count).to be(3)
      expect(
        grouped_attachments[0].map(&:filename)
      ).to eq(
        [
          pdf_attachment.filename,
          upload5['filename'],
          upload2['filename'],
          upload1['filename'],
          upload4['filename']
        ]
      )
      expect(grouped_attachments[1].map(&:filename)).to eq([upload3['filename']])
      expect(grouped_attachments[2].map(&:filename)).to eq([upload6['filename']])
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
