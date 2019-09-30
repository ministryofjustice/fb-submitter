class AttachmentParserService
  def initialize(attachments:)
    @attachments = attachments
  end

  def execute
    attachments.map do |attachment|
      Attachment.new(
        url: attachment.fetch(:url),
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
