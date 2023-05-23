class AttachmentParserService
  def initialize(attachments:)
    @attachments = attachments
  end

  def execute
    attachments.map do |attachment|
      Attachment.new(
        url: attachment.fetch('url', nil),
        mimetype: attachment.fetch('mimetype'),
        filename: attachment.fetch('filename'),
        type: attachment.fetch('type', nil),
        path: nil
      )
    rescue KeyError
      Rails.logger.error "Couldn\'t parse the attachment #{attachment} and will skip it"
    end
  end

  private

  attr_reader :attachments
end
