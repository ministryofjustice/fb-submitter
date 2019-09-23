class PublicAttachmentService
  def initialize(user_file_store_gateway:)
    @user_file_store_gateway = user_file_store_gateway
  end

  def execute(url_list)
    url_list.map do |url|
      @user_file_store_gateway.get_presigned_url(url)
    end
  end
end
