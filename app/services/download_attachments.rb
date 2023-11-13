class DownloadAttachments
  SUBSCRIPTION = 'download_attachments'.freeze
  DEFAULT_OPEN_TIMEOUT = 10
  DEFAULT_READ_TIMEOUT = 30

  attr_reader :attachments, :encrypted_user_id_and_token, :access_token,
              :target_dir, :request_id, :jwt_skew_override

  def initialize(attachments:, encrypted_user_id_and_token:, access_token:, **options)
    @attachments = attachments
    @encrypted_user_id_and_token = encrypted_user_id_and_token
    @access_token = access_token

    @target_dir = options[:target_dir] || Dir.mktmpdir
    @request_id = options[:request_id]
    @jwt_skew_override = options[:jwt_skew_override]
  end

  def download
    results = []

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

      # Number of seconds to wait for the connection to open
      conn.options.open_timeout = DEFAULT_OPEN_TIMEOUT

      # Number of seconds to wait for one block to be read
      conn.options.read_timeout = DEFAULT_READ_TIMEOUT
    end

    response = connection.get('', {}, headers)

    File.open(file_path, 'wb') do |f|
      f.write(response.body)
    end
  end

  def headers
    {
      'x-encrypted-user-id-and-token' => encrypted_user_id_and_token,
      'x-access-token-v2' => access_token,
      'x-jwt-skew-override' => jwt_skew_override,
      'X-Request-Id' => request_id
    }.compact
  end

  def file_path_for_download(url:)
    filename = File.basename(URI.parse(url).path)
    File.join(target_dir, filename)
  end
end
