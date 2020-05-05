class AttachmentGenerator
  # AWS SES limit is 10MB for each email message including all attachments and images
  # https://aws.amazon.com/ses/faqs/#Limits_and_Restrictions
  # Leaving a 3MB headroom for email body contents and the fact that the attachments
  # get base64 encoded before being sent
  MAX_EMAIL_SIZE = 7_000_000

  def initialize(action:, download_service:, payload_attachments:, pdf_attachment:)
    @action = action
    @download_service = download_service
    @attachments = generate(payload_attachments)
    @pdf_attachment = pdf_attachment
  end

  def grouped_attachments
    email_attachments = []
    email_attachments.concat(by_size(attachments)) if action.fetch(:include_attachments, false)
    email_attachments.prepend(pdf_attachment) if action.fetch(:include_pdf, false)
    attachments_per_email(email_attachments)
  end

  private

  attr_reader :action, :download_service, :attachments, :pdf_attachment

  def generate(payload_attachments)
    payload_attachments.map do |attachment|
      url = attachment.fetch('url')
      filename = attachment.fetch('filename')
      mimetype = attachment.fetch('mimetype')
      size = download_service.get_file_size(url)
      Attachment.new(url: url, filename: filename, mimetype: mimetype, size: size)
    end
  end

  def by_size(attachments)
    attachments.sort_by { |attachment| attachment.size }
  end

  def attachments_per_email(email_attachments)
    sorted_attachments = []
    per_email = []
    email_attachments.each do |attachment|
      if sum(per_email, attachment) >= MAX_EMAIL_SIZE
        sorted_attachments << per_email
        if attachment == email_attachments.last
          sorted_attachments << [attachment]
        else
          per_email = [attachment]
        end
      else
        per_email << attachment
        sorted_attachments << per_email if attachment == email_attachments.last
      end
    end
    sorted_attachments
  end

  def sum(per_email, to_add)
    per_email.map(&:size).sum + to_add.size
  end
end
