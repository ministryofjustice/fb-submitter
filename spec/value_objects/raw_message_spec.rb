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
    build(
      :attachment,
      filename:,
      mimetype:,
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
      Content-Disposition: attachment; filename="#{expected_filename}"
      Content-Transfer-Encoding: base64

      aGVsbG8gd29ybGQK



    EMAIL
  end
  let(:filename) { 'some-file-name.jpg' }
  let(:mimetype) { 'application/pdf' }
  let(:expected_filename) { 'some-file-name.jpg' }

  it 'uses correct filename and extension' do
    expect(subject.to_s).to include(expected_filename)
  end

  it 'creates the expected raw message' do
    expect(subject.to_s).to eq(expected_email)
  end

  context 'when filename has multiple fullstops' do
    let(:filename) { 'Screenshot 2023-04-04 at 16.02.20.png' }
    let(:mimetype) { 'application/pdf' }
    let(:expected_filename) { 'Screenshot 2023-04-04 at 16.02.20.png' }

    it 'uses maintains the filename' do
      expect(subject.to_s).to include(expected_filename)
    end

    it 'creates the expected raw message' do
      expect(subject.to_s).to eq(expected_email)
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
      expect(subject.to_s).to include('some-file-name.pdf')
    end
  end
end
