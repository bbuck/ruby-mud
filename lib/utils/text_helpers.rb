module TextHelpers
  class << self
    def header_with_title(title, char = "=", line_length = Laeron.config.text.line_length)
      header = char * 4
      header += " #{title} "
      remaining = header.purge_colors.length
      header += "[f:white:b]" + (char * (line_length - remaining))
      "[f:white:b]#{header}[reset]"
    end

    def full_line(char, line_length = Laeron.config.text.line_length)
      char * line_length
    end

    def string(*args)
      if args.first.kind_of?(Array)
        args.first.join("\n")
      else
        args.join("\n")
      end
    end
  end
end