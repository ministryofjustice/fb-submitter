class Attachment
  attr_accessor :type, :filename, :url, :mimetype, :path

  def initialize(filename:, mimetype:, type: nil, url: nil, path: nil)
    Rails.logger.info '*************** Attachment initialisation'
    Rails.logger.info type
    Rails.logger.info filename
    Rails.logger.info url
    Rails.logger.info mimetype
    Rails.logger.info path

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

    "#{raw_filename}.#{ext}"
  end

  def size
    File.size(path)
  end
end
