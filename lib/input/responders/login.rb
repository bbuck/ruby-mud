InputManager.respond_to :login do
  parse_input_with /new/i do |conn|
    conn.send_text("You want to create a character")
  end

  parse_input_with /(.+)/i do |conn, input|
    if conn.player.nil?
      conn.send_text("You want to login as \"#{input.capitalize}\"!")
    end
  end
end