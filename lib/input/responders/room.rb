InputManager.respond_to :standard do
  parse_input_with /l|look/ do |conn|
    conn.send_text(conn.player.room.display_text(conn.player))
  end
end