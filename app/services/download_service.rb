class DownloadService
  attr_reader :attachments, :target_dir, :token

  def initialize(attachments:, target_dir: nil, token:)
    @attachments = attachments
    @target_dir = target_dir
    @token = token
  end

  def download_in_parallel
    actual_dir = target_dir || Dir.mktmpdir
    results = []

    hydra = Typhoeus::Hydra.hydra

    attachments.each do |attachment|
      url = attachment.fetch('url')
      filename = attachment.fetch('filename')
      mimetype = attachment.fetch('mimetype')
      tmp_path = file_path_for_download(url: url, target_dir: actual_dir)
      request = construct_request(url: url, file_path: tmp_path, headers: headers)
      results << { url: url, tmp_path: tmp_path, filename: filename, mimetype: mimetype }

      hydra.queue(request)
    end
    hydra.run
    results
  end

  private

  def headers
    { 'x-encrypted-user-id-and-token' => token }
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
