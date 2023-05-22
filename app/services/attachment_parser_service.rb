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
        mimetype: attachment.fetch(:mimetype),
        filename: attachment.fetch(:filename),
        type: attachment.fetch(:type),
        path: nil
      )
    end
  end

  private

  attr_reader :attachments
end
