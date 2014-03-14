class ClientConnection < EM::Connection
  class << self
    def timeout_inactive_players
      Laeron.config.logger.debug("Starting a player timeout check.")
      Player.each_connection do |connection|
        next if connection.player.can_administrate?
        if connection.has_timedout?
          connection.timeout
        end
      end
    end

    def eleetscript_allow_methods
      :none
    end
  end

  attr_reader :input_state
  attr_accessor :player, :internal_state, :time_connected, :time_of_last_action

  def initialize
    self.input_state = :login
    self.time_of_last_action = self.time_connected = Time.now
    Laeron.config.logger.verbose("A client has connected from #{hostname}:#{ip_addr}")
    send_text("\n\nRunning LaeronMUD Server v#{Laeron.version}...", prompt: false)
    time_diff = (Time.now - Laeron.start_time).round
    send_text("uptime #{time_diff.long_time_string}...\n\n", prompt: false)
    send_text(GameSetting.display_title, prompt: false)
    send_text("Welcome to the Laeron, please enter your character's name or type \"new\"", prompt: false)
  end

  def receive_data(data)
    return quit if data =~ /\A(?:quit|exit)/i
    time_of_last_action = Time.now
    valid = true
    # HACK: Hack to prevent broken input
    if data.length == 5
      ords = data.chars.map { |chr| chr.ord }
      valid &&= ords != [255, 244, 255, 253, 6]
    end
    if valid
      InputManager.process(data, self)
    else
      InputManager.unknown_input(self)
    end
  end

  def input_state=(value)
    @input_state = value
    self.internal_state = nil
  end

  def send_text(text, opts = {})
    opts = default_write_options.merge(opts)
    text = text.colorize if opts[:colorize]
    text = clean_text(text)
    text = text.line_split unless opts[:raw]
    if text.is_a?(Array)
      last_line = text.pop
      last_line += "\n" if opts[:newline]
      text.each do |line|
        send_data(line)
      end
      send_data(last_line)
    else
      text += "\n" if opts[:newline]
      send_data(text.colorize)
    end
    if opts[:prompt]
      prompt = "[f:green]PROMPT >>"
      send_data("\n#{prompt}\n\n".colorize)
    end
  end

  def quit
    player.disconnect if player.present?
    time_diff = (Time.now - time_connected).round
    send_text("\n\n[f:yellow:b]Connected for #{time_diff.long_time_string}", prompt: false)
    send_text("[f:yellow:b]Thank you for playing!\n\n", prompt: false)
    close_connection_after_writing
  end

  def timeout
    send_text("\n\n[f:yellow:b]You have been idle longer than 10 minutes, your connection has timed out.", prompt: false)
    quit
  end

  def has_timedout?
    (Time.now - time_of_last_action) > 10.minutes
  end

  def hostname
    Socket.gethostname
  end

  def ip_addr
    @ip_addr ||= Socket.unpack_sockaddr_in(get_peername)[1]
  end

  private

  def clean_text(text)
    text.gsub(/\r/, "")
  end

  def default_write_options
    {
      newline: true,
      prompt: true,
      colorize: true,
      raw: false
    }
  end

  def eleetscript_allow_methods
    [:send_text]
  end
end