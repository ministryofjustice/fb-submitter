class WebhookAttachmentService
  def initialize(user_file_store_gateway:, attachments:)
    @user_file_store_gateway = user_file_store_gateway
    @attachments = attachments
  end

  def execute
    attachments.map do |attachment|
      user_file_store_gateway.get_presigned_url(attachment.fetch(:url))
    end
  end

  private

  attr_reader :user_file_store_gateway, :attachments
end
