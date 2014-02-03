class ClientConnection < EM::Connection
  attr_accessor :input_state, :player

  def initialize
    @input_state = :login
    send_text("Welcome to the Laeron Chat Test, please enter your username or type \"new\"")
  end

  def receive_data(data)
    quit if data =~ /quit|exit/i
    InputManager.process(data, self)
  end

  def send_text(text, opts = {})
    opts = default_write_options.merge(opts)
    text += "\n" if opts[:newline]
    send_data(clean_text(text))
  end

  def quit
    send_text("Thank you for playing!\n")
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