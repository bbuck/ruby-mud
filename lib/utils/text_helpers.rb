module TextHelpers
  class << self
    def header_with_title(title, char = "=")
      header = char * 4
      header += " #{title} "
      remaining = header.purge_colors.length
      header += "[f:white:b]" + (char * (80 - remaining))
      "[f:white:b]#{header}[reset]"
    end

    def full_line(char)
      char * 80
    end
  end
end