class AttachmentParserService
  def initialize(attachments:, v2submission: false)
    @attachments = attachments
    @v2submission = v2submission
  end

  def execute
    attachments.filter_map do |attachment|
      if @v2submission
        Attachment.new(
          url: attachment.fetch('url', nil),
          mimetype: attachment.fetch('mimetype'),
          filename: attachment.fetch('filename'),
          type: attachment.fetch('type', nil),
          path: nil
        )
      else
        Attachment.new(
          url: attachment.fetch(:url, nil),
          mimetype: attachment.fetch(:mimetype),
          filename: attachment.fetch(:filename),
          type: attachment.fetch(:type),
          path: nil
        )
      end
    rescue KeyError
      Rails.logger.error "Couldn't parse the attachment #{attachment} and will skip it"
      nil
    end
  end

  private

  attr_reader :attachments
end
