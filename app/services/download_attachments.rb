class DownloadAttachments
  SUBSCRIPTION = 'download_attachments'.freeze
  attr_reader :attachments, :target_dir, :token, :access_token

  def initialize(attachments:, target_dir: nil, token:, access_token:, jwt_skew_override:)
    @attachments = attachments
    @target_dir = target_dir
    @token = token
    @access_token = access_token
    @jwt_skew_override = jwt_skew_override
  end

  def download
    actual_dir = target_dir || Dir.mktmpdir
    results = []

    attachments.each do |attachment|
      url = attachment.fetch('url')
      filename = attachment.fetch('filename')
      mimetype = attachment.fetch('mimetype')
      tmp_path = file_path_for_download(url: url, target_dir: actual_dir)
      request(url: url, file_path: tmp_path, headers: headers)
      results << Attachment.new(url: url, path: tmp_path, filename: filename, mimetype: mimetype)
    end

    results
  end

  private

  def request(url:, file_path:, headers:)
    connection = Faraday.new(url) do |conn|
      conn.response :raise_error
      conn.use :instrumentation, name: SUBSCRIPTION
      conn.options[:open_timeout] = 30
      conn.options[:timeout] = 30
    end

    response = connection.get('', {}, headers)

    File.open(file_path, 'wb') do |f|
      f.write(response.body)
    end
  end

  attr_reader :jwt_skew_override

  def headers
    {
      'x-encrypted-user-id-and-token' => token,
      'x-access-token-v2' => access_token,
      'x-jwt-skew-override' => jwt_skew_override
    }.compact
  end

  def file_path_for_download(url:, target_dir: nil)
    actual_dir = target_dir || Dir.mktmpdir
    filename = File.basename(URI.parse(url).path)
    File.join(actual_dir, filename)
  end
end
