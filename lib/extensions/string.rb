require 'erb'

module Laeron
  module String
    class ERBContext
      include ActiveSupport::Inflector

      def initialize(hash)
        hash.each_pair do |key, value|
          singleton_class.send(:define_method, key) { value }
        end
      end

      def get_binding
        binding
      end
    end
  end
end

class String
  def purge_colors
    self.gsub(/\[reset\]/i, "").gsub(/\[[fb]:.+?\]/i, "")
  end

  def colorize(opts = {})
    opts = default_colorize_options.merge(opts)
    ret = gsub(/\[reset\]/i, ANSI::RESET)
    ret = ret.gsub(/(?<!__ESC__)\[([fb]:(?:.+?))\]/) do
      fore_or_background, method, bright = $1.match(/([fb]):(.+?)(?:(:b)|\z)/i)[1..3]
      method += "_background" if fore_or_background == "b"
      bright = bright.present?
      color = if ANSI.respond_to?(method)
        ANSI.send(method, bright)
      else
        "[#{Regexp.last_match[0]}]"
      end
      ANSI::RESET + color
    end
    ret = ret.gsub("__ESC__[", "[")
    ret += ANSI::RESET if opts[:include_reset] && !ret.ends_with?(ANSI::RESET)
    ret
  end

  def line_split(size = Laeron.config.text.line_length)
    buffer = self.split("\n")
    idx = 0
    while idx < buffer.length
      line = buffer[idx]
      if line.purge_colors.length <= size
        idx += 1
        next
      end
      line_idx = 0
      char_count = 0
      temp_str = ""
      new_portion = []
      while line_idx < line.length
        if line[line_idx] == ANSI::ESCAPE
          new_idx = line.index("m", line_idx)
          temp_str += line[line_idx..new_idx]
          line_idx = new_idx
        else
          temp_str += line[line_idx]
          char_count += 1
        end
        if char_count >= size
          if line[line_idx + 1] =~ /[a-z.?!, ]/i
            last_space = temp_str.rindex(" ") || 0
            new_str = temp_str[(last_space + 1)..-1]
            new_portion << temp_str[0...last_space]
            temp_str = new_str
            char_count = temp_str.length
          elsif line[line_idx + 1] == ANSI::ESCAPE
            new_idx = line.index("m", line_idx + 1)
            temp_str += line[(line_idx + 1)..new_idx]
            line_idx = new_idx
            new_portion << temp_str
            temp_str, char_count = "", 0
          else
            new_portion << temp_str
            temp_str, char_count = "", 0
          end
        end
        line_idx += 1
      end
      new_portion << temp_str
      buffer[idx..idx] = new_portion.select { |l| l.length > 0 }
      idx += new_portion.length
    end
    return buffer
  end

  def center_with_colors(len)
    diff = len - purge_colors.length
    return self if diff > len
    before = diff / 2
    after = diff - before
    before = 0 if before < 0
    after = 0 if after < 0
    (" " * before) + self + (" " * after)
  end

  def interval_value
    time = self.scan(/(\d+)([yMwdhms])/).inject(0) do |total, (amount, type)|
      amount = amount.to_i
      amount = case type
      when "y"
        amount.years.to_i
      when "M"
        amount.months.to_i
      when "w"
        amount.weeks.to_i
      when "d"
        amount.days.to_i
      when "h"
        amount.hours.to_i
      when "m"
        amount.minutes.to_i
      when "s"
        amount.seconds.to_i
      end
      total + amount
    end
  end

  def erb(assigns = {})
    ERB.new(self).result(Laeron::String::ERBContext.new(assigns).get_binding)
  end

  private

  def default_colorize_options
    {include_reset: true}
  end
end