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
    <<~RAW_MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}
      MIME-Version: 1.0
      Content-type: Multipart/Mixed; boundary="NextPart"

      --NextPart
      Content-type: Multipart/Alternative; boundary="AltPart"

      --AltPart
      Content-type: text/html; charset=utf-8
      Content-Transfer-Encoding: quoted-printable

      #{[@body_parts['text/html']].pack('M')}

      --AltPart
      Content-type: text/plain; charset=utf-8
      Content-Transfer-Encoding: quoted-printable

      #{[@body_parts['text/plain']].pack('M')}

      --NextPart
      #{@attachments.map { |attachment| inline_attachment(attachment) }.join("\n\n--NextPart\n")}

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
