class WebhookAttachmentService
  def initialize(user_file_store_gateway:, attachments:)
    @user_file_store_gateway = user_file_store_gateway
    @attachments = attachments
  end

  def execute
    attachments.map do |attachment|
      hash = user_file_store_gateway.get_presigned_url(attachment.fetch(:url))
      hash[:mimetype] = attachment.fetch(:mimetype)
      hash[:filename] = attachment.fetch(:filename)
      hash
    end
  end

  private

  attr_reader :user_file_store_gateway, :attachments
end
