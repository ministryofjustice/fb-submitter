require 'rails_helper'

RSpec.describe RawMessage do
  subject do
    described_class.new(
      from: 'sender@example.com',
      to: 'reciver@example.com',
      subject: 'test email',
      body_parts: {
        'text/plain': 'this is a plaintext test'
      },
      attachments: [attachment]
    )
  end

  before do
    allow(File).to receive(:read).and_return('hello world')
  end

  let(:attachment) do
    Attachment.new(
      type: nil,
      filename: 'some-file-name.jpg',
      url: nil,
      mimetype: 'application/pdf',
      path: file_fixture('hello_world.txt')
    )
  end

  let(:expected_email) do
    <<~EMAIL
      From: sender@example.com
      To: reciver@example.com
      Subject: test email
      MIME-Version: 1.0
      Content-type: Multipart/Mixed; boundary="NextPart"

      --NextPart
      Content-type: Multipart/Alternative; boundary="AltPart"

      --AltPart
      Content-type: text/plain; charset=utf-8
      Content-Transfer-Encoding: quoted-printable

      this is a plaintext test=


      --NextPart
      Content-Type: application/pdf
      Content-Disposition: attachment; filename="some-file-name.pdf"
      Content-Transfer-Encoding: base64

      aGVsbG8gd29ybGQK



    EMAIL
  end

  it 'uses correct filename and extension' do
    expect(subject.to_s).to include('some-file-name.pdf')
  end

  it 'creates the expected raw message' do
    expect(subject.to_s).to eq(expected_email)
  end

  context 'when filename does not have extension' do
    let(:attachment) do
      Attachment.new(
        type: nil,
        filename: 'some-file-name',
        url: nil,
        mimetype: 'application/pdf',
        path: file_fixture('hello_world.txt')
      )
    end

    it 'uses correct extension for given mimetype' do
      expect(subject.to_s).to include('some-file-name.pdf')
    end
  end
end
