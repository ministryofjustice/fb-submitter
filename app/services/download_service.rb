class DownloadService
  # returns Hash
  # {"https://my.domain/some/path/file.ext"=>"/the/file/path/file.ext"}
  def self.download_in_parallel(urls:, target_dir: nil, headers: {})
    new(urls: urls, target_dir: target_dir, headers: headers).download_in_parallel
  end

  attr_reader :urls, :target_dir, :headers

  def initialize(urls:, target_dir: nil, headers: {})
    @urls = urls
    @target_dir = target_dir
    @headers = headers
  end

  def download_in_parallel
    actual_dir = target_dir || Dir.mktmpdir
    results = {}

    hydra = Typhoeus::Hydra.hydra

    urls.each do |url|
      file = file_path_for_download(url: url, target_dir: actual_dir)
      request = construct_request(url: url, file_path: file, headers: headers)
      results[url] = file
      hydra.queue(request)
    end
    hydra.run
    results
  end

  private

  def download(url:, target_dir: nil, headers: {})
    path = file_path_for_download(url: url, target_dir: target_dir)
    request = construct_request(url: url, file_path: path, headers: headers)
    request.run
    path
  end

  def construct_request(url:, file_path:, headers: {})
    request = Typhoeus::Request.new(url, followlocation: true, headers: headers)
    request.on_headers do |response|
      raise "Request failed (#{response.code}: #{response.return_code} #{request.url})" if response.code != 200
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
