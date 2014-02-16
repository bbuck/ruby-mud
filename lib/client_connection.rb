class ClientConnection < EM::Connection
  attr_accessor :input_state, :player, :internal_state

  def initialize
    @input_state = :login
    @connected = Time.now
    send_text("\n\nRunning LaeronMUD Server v#{Laeron.version}...", prompt: false)
    time_diff = (Time.now - Laeron.start_time).round
    send_text("uptime #{time_diff.long_time_string}...\n\n", prompt: false)
    send_text(GameSetting.display_title, prompt: false)
    send_text("Welcome to the Laeron, please enter your character's name or type \"new\"", prompt: false)
  end

  def receive_data(data)
    return quit if data =~ /\A(?:quit|exit)/i
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
    @internal_state = nil
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
      prompt = opts[:newline] ? "\n" : ""
      prompt += "[f:green]PROMPT >>"
      send_data("#{prompt}\n".colorize)
    end
  end

  def quit
    if player
      Player.disconnect(player, self)
    end
    time_diff = (Time.now - @connected).round
    send_text("\n\n[f:yellow:b]Connected for #{time_diff.long_time_string}", prompt: false)
    send_text("[f:yellow:b]Thank you for playing!\n\n", prompt: false)
    close_connection_after_writing
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
end