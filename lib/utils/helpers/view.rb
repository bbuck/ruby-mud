module Helpers
  class View
    WRAP_MODE = "-"

    class << self
      def render(view_name, data = {})
        view_key = view_name.to_sym
        path = view_path(view_name)
        unless File.exists?(path)
          view_cache.delete(view_key)
          return nil
        end
        view_data = view_cache[view_key]
        file_hash = Digest::MD5.file(path).hexdigest
        erb = if view_data
          if view_data[:hash] == file_hash
            view_data[:erb]
          else
            contents = File.read(path)
            cache(view_key, file_hash, ERB.new(contents, nil, View::WRAP_MODE))
            view_cache[view_key][:erb]
          end
        else
          contents = File.read(path)
          cache(view_key, file_hash, ERB.new(contents, nil, View::WRAP_MODE))
          view_cache[view_key][:erb]
        end
        context = Laeron::String::ERBContext.new(data)
        context.extend_methods_from(Helpers::Text)
        erb.result(context.get_binding) unless erb.nil?
      end

      private

      def load_view_file(hash, path)
        {
          hash: hash,
          erb: ERB.new(File.read(path), nil, View::WRAP_MODE)
        }
      end

      def view_path(str)
        path_elements = str.split(".")
        path_elements[-1] += ".erb"
        Laeron.root.join("lib", "views", *path_elements)
      end

      def cache(view_name, hash, erb)
        view_cache[view_name] = {hash: hash, erb: erb}
      end

      def cached?(view_name)
        view_cache.has_key?(view_name)
      end

      def view_cache
        @view_cache ||= {}
      end
    end
  end
end