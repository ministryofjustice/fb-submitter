require 'rails_helper'

RSpec.describe V2::RawMessage do
  subject(:raw_message) do
    described_class.new(
      from: 'Service name <sender@example.com>',
      to: 'reciver@example.com',
      subject: 'Submission from service name, reference number: AJ9-U2R4-EHC {25db2d01-f017-4d8f-9590-435435b06233} [1/2]',
      body_parts: {
        'text/plain': 'some body',
        'text/html': 'some body'
      },
      attachments:,
      variant:
    )
  end

  before do
    allow(File).to receive(:read).and_return('hello world')
  end

  let(:variant) { described_class::ACTION_CONFIRMATION }
  let(:attachments) { [attachment] }
  let(:attachment) do
    build(
      :attachment,
      filename: 'some-file-name.jpg',
      mimetype: 'application/pdf',
      path: file_fixture('hello_world.txt')
    )
  end
  let(:body) { raw_message.send(:body) }
  let(:expected_email) do
    <<~RAW_MESSAGE
      From: Service name <sender@example.com>
      To: reciver@example.com
      Subject: test email
      Content-Type: multipart/mixed; boundary="NextPart"

      --NextPart
      Content-Type: multipart/alternative; boundary="AltPart"

      --AltPart
      Content-Type: text/plain; charset=utf-8
      Content-Transfer-Encoding: quoted-printable

      some body=


      --AltPart
      Content-Type: text/html; charset=utf-8
      Content-Transfer-Encoding: base64

      #{Base64.encode64(body)}

      --AltPart--

      --NextPart
      Content-Type: application/pdf
      Content-Disposition: attachment; filename="some-file-name.pdf"
      Content-Description: some-file-name.pdf
      Content-Transfer-Encoding: base64

      aGVsbG8gd29ybGQK



      --NextPart--
    RAW_MESSAGE
  end

  it 'uses correct filename and extension' do
    expect(raw_message.to_s).to include('some-file-name.pdf')
  end

  it 'creates the expected raw message' do
    expect(raw_message.to_s).to eq(expected_email)
  end

  it 'adds the protective watermark' do
    expect(body).to match('OFFICIAL-SENSITIVE')
  end

  context 'when there are no attachments' do
    let(:attachments) { [] }

    it 'does not add the protective watermark' do
      expect(body).not_to match('OFFICIAL-SENSITIVE')
    end
  end

  context 'when variant is submission email' do
    let(:variant) { described_class::ACTION_SUBMISSION }

    it 'has a body heading with details of the submission' do
      expect(body).to match('Submission from Service name')
      expect(body).to match('ID: 25db2d01-f017-4d8f-9590-435435b06233')
      expect(body).to match('Email 1 of 2')
    end
  end

  context 'when filename does not have extension' do
    let(:attachment) do
      build(
        :attachment,
        filename: 'some-file-name',
        mimetype: 'application/pdf',
        path: file_fixture('hello_world.txt')
      )
    end

    it 'uses correct extension for given mimetype' do
      expect(raw_message.to_s).to include('some-file-name.pdf')
    end
  end
end
