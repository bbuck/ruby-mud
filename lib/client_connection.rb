class ClientConnection < EM::Connection
  attr_accessor :input_state, :player, :internal_state

  def initialize
    @input_state = :login
    send_text("Welcome to the Laeron Chat Test, please enter your username or type \"new\"")
  end

  def receive_data(data)
    return quit if data =~ /quit|exit/i
    InputManager.process(data, self)
  end

  def input_state=(value)
    @input_state = value
    @internal_state = nil
  end

  def send_text(text, opts = {})
    opts = default_write_options.merge(opts)
    text = clean_text(text).line_split unless opts[:raw]
    if text.is_a?(Array)
      last_line = text.pop
      last_line += "\n" if opts[:newline]
      last_line += ANSI::reset
      text.each do |line|
        send_data(line.colorize(false))
      end
      send_data(last_line.colorize(false))
    else
      text += "\n" if opts[:newline]
      send_data(clean_text(text).colorize)
    end
  end

  def quit
    send_text("\n\nThank you for playing!")
    close_connection_after_writing
  end

  private

  def clean_text(text)
    text.gsub(/\r/, "")
  end

  def default_write_options
    Hash.new({ newline: true })
  end
end