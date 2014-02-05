InputManager.respond_to :standard do
  parse_input_with /say (.+)/ do |conn, message|
    Player.connection_list.each do |c|
      c.send_text("[f:cyan:b]#{conn.player.username} says, \"#{message}\"")
    end
  end
end