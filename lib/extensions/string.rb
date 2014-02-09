class String
  def purge_colors
    self.gsub(/\[reset\]/i, "").gsub(/\[[fb]:.+?\]/i, "")
  end

  def colorize(include_reset = true)
    ret = self.gsub(/\[reset\]/i, ANSI::reset)
    ret = ret.gsub(/\[([fb]:(.+?))\]/) do
      code_tag = $1
      matches = code_tag.match(/([fb]):(.+)/i)
      method = matches[2] + (matches[1] == "f" ? "" : "_background")
      bright = if method.end_with?(":b")
        method = method[0..-3]
        true
      else
        false
      end
      ANSI::send(method, bright)
    end
    ret += ANSI::reset if include_reset
    ret
  end

  def line_split(size = 80)
    buffer = []
    i = 0
    count = 0
    str = ""
    while i < self.length
      if self[i] == ANSI::ESCAPE
        new_i = self.index("m", i + 1)
        str += self[i..new_i]
        i = new_i
      elsif self[i] == "\n"
        buffer << str
        str = ""
        count = 0
      else
        count = count + 1
        str += self[i]
      end
      if count == 80
        last_space = str.rindex(" ")
        new_str = str[(last_space + 1)..-1]
        buffer << str[0...last_space]
        str = new_str
        count = 0
      end
      i = i + 1
    end
    buffer << str
    if buffer.length == 0
      ""
    elsif buffer.length == 1
      buffer.first
    else
      buffer
    end
  end
end