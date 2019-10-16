class Attachment
  attr_accessor :type, :filename, :url, :mimetype, :path

  def initialize(type:, filename:, url:, mimetype:, path:)
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
    head, *tail = filename.split('.').reverse
    raw_filename = tail.reverse.join.presence || head
    ext = MIME::Types[@mimetype][0].preferred_extension

    "#{raw_filename}.#{ext}"
  end
end
