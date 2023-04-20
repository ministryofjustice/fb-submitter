class DownloadAttachments
  SUBSCRIPTION = 'download_attachments'.freeze
  TIMEOUT = 30
  OPEN_TIMEOUT = 30
  attr_reader :attachments, :target_dir, :encrypted_user_id_and_token, :access_token

  def initialize(attachments:, encrypted_user_id_and_token:, access_token:, jwt_skew_override:, target_dir: nil)
    @attachments = attachments
    @target_dir = target_dir || Dir.mktmpdir
    @encrypted_user_id_and_token = encrypted_user_id_and_token
    @access_token = access_token
    @jwt_skew_override = jwt_skew_override
  end

  def download
    results = []
    return if attachments.blank?

    attachments.each do |attachment|
      url = attachment.fetch('url')
      filename = attachment.fetch('filename')
      mimetype = attachment.fetch('mimetype')
      tmp_path = file_path_for_download(url:)
      request(url:, file_path: tmp_path, headers:)
      results << Attachment.new(url:, path: tmp_path, filename:, mimetype:)
    end

    results
  end

  private

  def request(url:, file_path:, headers:)
    connection = Faraday.new(url) do |conn|
      conn.response :raise_error
      conn.use :instrumentation, name: SUBSCRIPTION
      conn.options[:open_timeout] = OPEN_TIMEOUT
      conn.options[:timeout] = TIMEOUT
    end

    response = connection.get('', {}, headers)

    File.open(file_path, 'wb') do |f|
      f.write(response.body)
    end
  end

  attr_reader :jwt_skew_override

  def headers
    {
      'x-encrypted-user-id-and-token' => encrypted_user_id_and_token,
      'x-access-token-v2' => access_token,
      'x-jwt-skew-override' => jwt_skew_override
    }.compact
  end

  def file_path_for_download(url:)
    filename = File.basename(URI.parse(url).path)
    File.join(target_dir, filename)
  end
end
