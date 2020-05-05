class DownloadService
  attr_reader :target_dir, :token, :access_token

  def initialize(target_dir: nil, token:, access_token:)
    @target_dir = target_dir
    @token = token
    @access_token = access_token
  end

  def get_file_size(url)
    content_url = URI.join(url, 'content-length')
    response = Typhoeus::Request.new(content_url, followlocation: true, headers: headers).run
    JSON.parse(response)['content_length']
  end

  def download_in_parallel(attachments)
    actual_dir = target_dir || Dir.mktmpdir
    results = []

    hydra = Typhoeus::Hydra.hydra

    attachments.each do |attachment|
      tmp_path = file_path_for_download(url: attachment.url, target_dir: actual_dir)
      request = construct_request(url: attachment.url, file_path: tmp_path, headers: headers)
      attachment.path = tmp_path
      results << attachment

      hydra.queue(request)
    end
    hydra.run
    results
  end

  private

  def headers
    {
      'x-encrypted-user-id-and-token' => token,
      'x-access-token-v2' => access_token
    }
  end

  def construct_request(url:, file_path:, headers: {})
    request = Typhoeus::Request.new(url, followlocation: true, headers: headers)
    request.on_headers do |response|
      if response.code != 200
        raise "Request failed (#{response.code}: #{response.return_code} #{request.url})"
      end
    end
    open_file = File.open(file_path, 'wb')
    # writing a chunk at a time is way more efficient for large files
    # as Typhoeus won't then try to hold the whole body in RAM
    request.on_body do |chunk|
      open_file.write(chunk)
    end
    request.on_complete do |response|
      open_file.close
      raise "Request failed (#{response.code}: #{response.return_code} #{request.url})" if response.code != 200
      # Note that response.body is "", cause it's been cleared as we go
    end
    request
  end

  def file_path_for_download(url:, target_dir: nil)
    actual_dir = target_dir || Dir.mktmpdir
    filename = File.basename(URI.parse(url).path)
    File.join(actual_dir, filename)
  end
end
