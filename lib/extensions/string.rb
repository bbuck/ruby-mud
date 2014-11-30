require 'erb'

class ERBContext
  def initialize(hash)
    hash.each_pair do |key, value|
      singleton_class.send(:define_method, key) { value }
    end
  end

  def get_binding
    binding
  end
end

class String
  def purge_colors
    self.gsub(/\[reset\]/i, "").gsub(/\[[fb]:.+?\]/i, "")
  end

  def colorize(opts = {})
    opts = default_colorize_options.merge(opts)
    ret = gsub(/\[reset\]/i, ANSI::RESET)
    ret = ret.gsub(/(?<!__ESC__)\[([fb]:(.+?))\]/) do
      code_tag = $1
      matches = code_tag.match(/([fb]):(.+)/i)
      method = matches[2] + (matches[1] == "f" ? "" : "_background")
      bright = if method.end_with?(":b")
        method = method[0..-3]
        true
      else
        false
      end
      color = if ANSI.respond_to?(method)
        ANSI.send(method, bright)
      else
        "[#{Regexp.last_match[0]}]"
      end
      if bright
        color
      else
        ANSI::RESET + color
      end
    end
    ret = ret.gsub("__ESC__[", "[")
    ret += ANSI::RESET if opts[:include_reset]
    ret
  end

  def line_split(size = Laeron.config.text.line_length)
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
        buffer << str + "\n"
        str = ""
        count = 0
      else
        count = count + 1
        str += self[i]
      end
      if count >= size
        if self[i + 1] =~ /[a-z.?!, ]/i
          last_space = str.rindex(" ")
          last_space ||= 0
          new_str = str[(last_space + 1)..-1]
          buffer << str[0...last_space] + "\n"
          str = new_str
          count = str.length
        else
          i += 1 if self[i + 1] == "\n"
          buffer << str + "\n"
          count = 0
          str = ""
        end
      end
      i += 1
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

  def interval_value
    time = self.scan(/(\d+)([yMwdhms])/).inject(0) do |total, (amount, type)|
      amount = amount.to_i
      amount = case type
      when "y"
        amount.years
      when "M"
        amount.months
      when "w"
        amount.weeks
      when "d"
        amount.days
      when "h"
        amount.hours
      when "m"
        amount.minutes
      when "s"
        amount.seconds
      end
      total + amount
    end
  end

  def erb(assigns = {})
    ERB.new(self).result(ERBContext.new(assigns).get_binding)
  end

  private

  def default_colorize_options
    {include_reset: true}
  end
end