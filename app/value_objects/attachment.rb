class Attachment
  attr_accessor :type, :filename, :url, :mimetype, :path

  def initialize(filename:, mimetype:, type: nil, url: nil, path: nil)
    @type = type
    @filename = filename
    @url = url
    @mimetype = mimetype
    @path = path
  end

  def file=(file)
    @file = file # hold a reference as TempFiles are erased when garbage collected
    @path = file.path
  end

  def filename_with_extension
    head, *tail = filename.rpartition('.').reverse
    raw_filename = tail.last.presence || head
    ext = MIME::Types[@mimetype][0].preferred_extension

    return "#{raw_filename}.#{ext}" if raw_filename == head

    filename
  end

  def size
    File.size(path)
  end
end
