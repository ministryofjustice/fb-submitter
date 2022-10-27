class RawMessage
  attr_accessor :from, :to, :subject, :body_parts, :attachments

  def initialize(opts = {})
    symbol_params = opts.dup.symbolize_keys!
    @attachments  = symbol_params[:attachments]
    @body_parts   = symbol_params[:body_parts]
    @from         = symbol_params[:from]
    @subject      = symbol_params[:subject]
    @to           = symbol_params[:to]
  end

  def to_s
    inline_attachments = @attachments.map do |attachment|
      inline_attachment(attachment)
    end

    Rails.logger.info("Attachments size: #{inline_attachments.join.bytesize}")

    <<~RAW_MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}
      MIME-Version: 1.0
      Content-type: Multipart/Mixed; boundary="NextPart"

      --NextPart
      Content-type: Multipart/Alternative; boundary="AltPart"

      --AltPart
      Content-type: text/plain; charset=utf-8
      Content-Transfer-Encoding: quoted-printable

      #{[@body_parts[:'text/plain']].pack('M')}

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
                            <p>#{@body_parts[:'text/plain']}</p>
                        </div>
                    </td>
                </tr>
            </table>
        </body>
      </html>

      --AltPart--

      --NextPart
      #{inline_attachments.join("\n\n--NextPart\n")}

    RAW_MESSAGE
  end

  private

  def inline_attachment(attachment)
    <<~RAW_ATTACHMENT
      Content-Type: #{attachment.mimetype}
      Content-Disposition: attachment; filename="#{attachment.filename_with_extension}"
      Content-Transfer-Encoding: base64

      #{Base64.encode64(File.open(attachment.path, 'rb', &:read))}
    RAW_ATTACHMENT
  end
end
