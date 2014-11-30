module Laeron
  @config = Configuration.new

  class << self
    def version
      "0.0.1 alpha"
    end

    def start_time
      @start_time ||= Time.now
    end

    def env
      (ENV["LAERON_ENV"] || "development").downcase
    end

    def config(&block)
      if block_given?
        yield(@config)
      else
        @config
      end
    end

    def root
      @root_path ||= Pathname.new(__FILE__).join("../..")
    end

    def kill_server
      EM.stop
    end

    def start_server
      @start_time = Time.now
      EM.run do
        Signal.trap("INT") { kill_server }
        Signal.trap("TERM") { kill_server }

        EM.start_server(Laeron.config.host, Laeron.config.port, Net::ClientConnection)
        config.logger.debug("Laeron running on #{Laeron.config.host}:#{Laeron.config.port}")

        EM::PeriodicTimer.new(1.minute) { Net::ClientConnection.timeout_inactive_players }
        EM::PeriodicTimer.new(1.minute) { Helpers::Room.check_all_doors_and_locks }
      end
    end

    def require_all(path, recursive = true)
      Dir.glob(path).each do |file|
        if !File.directory?(file)
          require file
        elsif recursive
          require_all(Pathname.new(file).join("*").to_s)
        end
      end
    end
  end
end

# Plug for ActiveRecord, it's got a hard dependency on Rails
Rails = Laeron