require 'rails_helper'

RSpec.describe V2::RawMessage do
  subject(:raw_message) do
    described_class.new(
      from: 'Service name <sender@example.com>',
      to: 'reciver@example.com',
      subject: 'test email',
      body_parts: {
        'text/plain': 'some body',
        'text/html': 'some body'
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
  let(:body) do
    <<~RAW_MESSAGE
      <html>
        <body style="font-family: Helvetica, Arial, sans-serif;font-size: 16px;margin: 0;color:#0b0c0c;">

          <!-- govuk banner -->
          <table role="presentation" width="100%" style="border-collapse: collapse;min-width: 100%;width: 100% !important;" cellpadding="0" cellspacing="0" border="0">
              <tr>
                  <td width="100%" height="53" bgcolor="#0b0c0c">
                      <!--[if (gte mso 9)|(IE)]>
                          <table role="presentation" width="580" align="center" cellpadding="0" cellspacing="0" border="0" style="border-collapse: collapse;width: 580px;">
                          <tr>
                          <td>
                      <![endif]-->
                      <table role="presentation" width="100%" style="border-collapse: collapse;max-width: 580px;" cellpadding="0" cellspacing="0" border="0" align="center">
                          <tr>
                              <td width="70" bgcolor="#0b0c0c" valign="middle">
                                  <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="border-collapse: collapse;">
                                      <tr>
                                          <td style="padding-left: 10px">
                                              <img
                                                  src="https://static.notifications.service.gov.uk/images/gov.uk_logotype_crown.png"
                                                  alt=""
                                                  height="32"
                                                  border="0"
                                                  style="Margin-top: 4px;"
                                                  />
                                          </td>
                                          <td style="font-size: 28px; line-height: 1.315789474; Margin-top: 4px; padding-left: 10px;">
                                              <span style="
                                              font-family: Helvetica, Arial, sans-serif;
                                              font-weight: 700;
                                              color: #ffffff;
                                              text-decoration: none;
                                              vertical-align:top;
                                              display: inline-block;
                                              ">Service name</span>
                                          </td>
                                      </tr>
                                  </table>
                              </td>
                          </tr>
                      </table>
                      <!--[if (gte mso 9)|(IE)]>
                          </td>
                          </tr>
                          </table>
                      <![endif]-->
                  </td>
              </tr>
          </table>
          <table
              role="presentation"
              class="content"
              align="center"
              cellpadding="0"
              cellspacing="0"
              border="0"
              style="border-collapse: collapse;max-width: 580px; width: 100% !important;"
              width="100%"
              >
              <tr>
                  <td width="10" height="10" valign="middle"></td>
                  <td>
                      <!--[if (gte mso 9)|(IE)]>
                          <table role="presentation" width="560" align="center" cellpadding="0" cellspacing="0" border="0" style="border-collapse: collapse;width: 560px;">
                          <tr>
                          <td height="10">
                      <![endif]-->
                      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="border-collapse: collapse;">
                          <tr>
                              <td bgcolor="#1D70B8" width="100%" height="10"></td>
                          </tr>
                      </table>
                      <!--[if (gte mso 9)|(IE)]>
                          </td>
                          </tr>
                          </table>
                      <![endif]-->
                  </td>
                  <td width="10" valign="middle" height="10"></td>
              </tr>
          </table>
          <!-- end govuk banner -->

          <table
              role="presentation"
              class="content"
              align="center"
              cellpadding="0"
              cellspacing="0"
              border="0"
              style="border-collapse: collapse;max-width: 580px; width: 100% !important;"
              width="100%"
              >
              <tr>
                  <td colspan="3" height="65" style="padding-bottom: 12px; padding-right: 9px; text-align: right; font-weight: lighter; letter-spacing: 1px;">
                    OFFICIAL-SENSITIVE
                  </td>
              </tr>
              <tr>
                  <td width="10" valign="middle"><br /></td>
                  <td style="font-family: Helvetica, Arial, sans-serif; font-size: 19px; line-height: 1.315789474; max-width: 560px;">
                      <!--[if (gte mso 9)|(IE)]>
                          <table role="presentation" width="560" align="center" cellpadding="0" cellspacing="0" border="0" style="border-collapse: collapse;width: 560px;">
                          <tr>
                          <td style="font-family: Helvetica, Arial, sans-serif; font-size: 19px; line-height: 1.315789474;">
                      <![endif]-->

                      #{raw_message.body_parts[:'text/html']}

                      <!--[if (gte mso 9)|(IE)]>
                          </td>
                          </tr>
                          </table>
                      <![endif]-->
                  </td>
                  <td width="10" valign="middle"><br /></td>
              </tr>
              <tr>
                  <td height="30"><br /></td>
              </tr>
          </table>
        </body>
      </html>
    RAW_MESSAGE
  end
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
