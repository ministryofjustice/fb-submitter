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
      filename: 'some-file-name.jpg',
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


      --AltPart
      Content-Type: text/html; charset=iso-8859-1
      Content-Transfer-Encoding: quoted-printable

      <html>
        <head>
            <style>
                html, body {
                    background-color: #fff;
                    color: #0b0c0c;
                    font-family: arial, sans-serif;
                }
                p {
                    color: #0b0c0c;
                    font-size: 19px;
                }
            </style>
        </head>
        <body style="background-color: #fff; color: #0b0c0c; font-family: arial, sans-serif;">
            <table width="100%" style="background-color: #fff; border-collapse: collapse;" cellspacing="0" cellpadding="0">
                <tr>
                    <td style="background-color: #0b0c0c; padding: 10px 20px;">
                        <table width="100" style="width: 100%; border-collapse: collapse;" cellspacing="0" cellpadding="0">
                            <tbody>
                                <a href="#" style="display: flex; align-items: center; font-size: 30px; font-weight: 700; color: #fff; line-height: 1;">
                                    <img src="https://design-system.service.gov.uk/assets/images/govuk-logotype-crown.png" style="display: inline-block; padding-right: 12px;"/><span>GOV.UK</span>
                                </a>
                            </tbody>
                        </table>
                    </td>
                </tr>
                <tr>
                    <td style="background-color: #1d70b8; height: 10px"></td>
                </tr>
                <tr>
                    <td style="background-color: #fff; padding: 30px 20px;">
                        <div style="min-width: 260px; max-width: 65ch; font-size: 19px;">
                            <p>this is a plaintext test</p>
                        </div>
                    </td>
                </tr>
            </table>
        </body>
      </html>

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
