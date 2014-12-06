module Helpers
  class View
    class << self
      def render(view_name, data = {})
        sym = view_name.to_sym
        view = if !view_cache[sym]
          path = view_path(view_name)
          if File.exists?(path)
            view_cache[sym] = ERB.new(File.read(path))
          else
            nil
          end
        else
          view_cache[sym]
        end
        context = Laeron::String::ERBContext.new(data)
        context.extend_methods_from(Helpers::Text)
        view.result(context.get_binding) unless view.nil?
      end

      private

      def view_path(str)
        path = str.gsub(".", File::SEPARATOR)
        path = Pathname.new(path)
        path = path.dirname.join(path.basename.to_s + ".erb")
        Laeron.root.join("lib", "views", path)
      end

      def view_cache
        @view_cache ||= {}
      end
    end
  end
end