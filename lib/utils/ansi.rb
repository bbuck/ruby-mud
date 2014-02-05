class ANSI
  COLORS = [
    :black,
    :red,
    :green,
    :yellow,
    :blue,
    :magenta,
    :cyan,
    :white
  ]

  ESCAPE = "\e"

  FOREGROUND = "3"
  BACKGROUND = "4"

  class << self
    COLORS.each_with_index do |color, index|
      define_method color do |bright = false|
        color(FOREGROUND, index, bright)
      end

      define_method "#{color}_background" do |bright = false|
        color(BACKGROUND, index, bright)
      end
    end

    def hidden
      "#{ESCAPE}[8m"
    end

    def reset
      "#{ESCAPE}[0m"
    end

    def wrap(text, color_method, bright = false)
      open = send(color_method, bright)
      "#{open}#{text}#{reset}"
    end

    private

    def color(fore_or_back, color_code, bright)
      code = "#{ESCAPE}["
      code += "1;" if bright
      code += "#{fore_or_back}#{color_code}m"
    end
  end
end