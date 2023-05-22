class AttachmentParserService
  def initialize(attachments:)
    @attachments = attachments
  end

  def execute
    attachments.map do |attachment|
      Rails.logger.info '************* Attachment parser'
      Rails.logger.info attachment.to_s
      Attachment.new(
        url: attachment.fetch(:url, nil),
        mimetype: attachment.fetch(:mimetype) { MIME::Types.type_for(attachment[:filename]).first.content_type },
        filename: attachment.fetch(:filename),
        type: attachment.fetch(:type),
        path: nil
      )
    end
  end

  private

  attr_reader :attachments
end
