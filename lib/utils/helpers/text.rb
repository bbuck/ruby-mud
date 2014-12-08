module Helpers
  module Text
    extend Memoist

    def header_with_title(title, options = {})
      options = options.reverse_merge({
        char: "=",
        line_length: Laeron.config.text.line_length,
        line_color: "",
        title_color: ""
      })
      str = "" + options[:line_color] + (options[:char] * 4)
      str += "[reset]" if options[:title_color].length == 0 && options[:line_color].length > 0
      str += options[:title_color] + " #{title} "
      str += "[reset]" if options[:title_color].length > 0 && options[:line_color].length == 0
      str += options[:line_color]
      str += (options[:char] * (options[:line_length] - str.purge_colors.length))
      str += "[reset]" if options[:line_color].length > 0
      str
    end
    memoize :header_with_title

    def full_line(char, options = {})
      options = options.reverse_merge({
        line_cap: char,
        line_length: Laeron.config.text.line_length,
        color: ""
      })
      target_len = options[:line_length] - (options[:line_cap].length * 2)
      str = "" + options[:color]
      str += options[:line_cap]
      str += (char * target_len)
      str += options[:line_cap]
      str += "[reset]" if options[:color].length > 0
      str
    end
    memoize :full_line

    def string(*args)
      if args.first.kind_of?(Array)
        args.first.join("\n")
      else
        args.join("\n")
      end
    end

    def pluralize(count, word)
      "#{count} #{word.pluralize(count)}"
    end

    module_function *instance_methods
  end
end