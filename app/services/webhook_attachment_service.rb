class WebhookAttachmentService
  def initialize(user_file_store_gateway:, attachment_parser:)
    @user_file_store_gateway = user_file_store_gateway
    @attachment_parser = attachment_parser
  end

  def execute
    attachments = attachment_parser.execute
    attachments.map do |attachment|
      Rails.logger.info '*************** Webhook'
      Rails.logger.info attachment
      Rails.logger.info attachment.url
      hash = user_file_store_gateway.get_presigned_url(attachment.url)
      hash[:mimetype] = attachment.mimetype
      hash[:filename] = attachment.filename_with_extension
      hash
    end
  end

  private

  attr_reader :user_file_store_gateway, :attachment_parser
end
