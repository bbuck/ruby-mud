module Game
  class ChannelFormatter
    class << self
      def create_formats(&block)
        class_eval(&block)
      end

      def register_format(name, format)
        formats[name] = format
      end

      def format(name, data)
        format = formats[name]
        if format.nil?
          ""
        else
          data.each do |key, value|
            format.gsub!(key, value)
          end
          format
        end
      end

      private

      def formats
        @formats ||= {}
      end
    end
  end
end

require Laeron.root.join("config", "game", "channels")