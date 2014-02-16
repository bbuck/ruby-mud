module Laeron
  @@config = Configuration.new

  class << self
    def version
      "0.0.1 alpha"
    end

    def start_time
      @@start_time ||= Time.now
    end

    def env
      (ENV["LAERON_ENV"] || "development").downcase
    end

    def config(&block)
      if block_given?
        yield(@@config)
      else
        @@config
      end
    end

    def root
      @@root_path ||= Pathname.new(__FILE__).join("../..")
    end

    def kill_server
      EM.stop
    end

    def start_server
      EM.run do
        Signal.trap("INT") { kill_server }
        Signal.trap("TERM") { kill_server }

        EM.start_server Laeron.config.host, Laeron.config.port, ClientConnection
        puts "Laeron running on #{Laeron.config.host}:#{Laeron.config.port}"
      end
    end

    def require_all(path)
      Dir.glob(path).each do |file|
        require file
      end
    end
  end
end

# Plug for ActiveRecord, it's got a hard dependency on Rails
Rails = Laeron

Laeron.start_time