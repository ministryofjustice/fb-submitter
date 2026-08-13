module StringUtils
  def self.mask(str)
    return str if str.length <= 4

    "#{str[0, 2]}***#{str[-2, 2]}"
  end
end
