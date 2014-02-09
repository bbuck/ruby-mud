InputManager.respond_to :standard do
  parse_input_with /say (.+)/ do |conn, message|
    message = message.purge_colors
    conn.player.room.transmit("[f:cyan:b]#{conn.player.username} says, \"#{message}\"")
  end

  parse_input_with /yell (.+)/ do |conn, message|
    message = message.purge_colors
    yell = "[f:red:b]#{conn.player.username} yells, \"#{message}\""
    Yell.new(yell, conn.player.room)
  end

  parse_input_with [/xme (.+)/,
                    /xpost (.+)/] do |conn, message|
    message = message.purge_colors
    conn.player.room.transmit("[f:green]#{message}")
  end

  parse_input_with [/me (.+)/,
                    /post (.+)/] do |conn, message|
    message = message.purge_colors
    conn.player.room.transmit("[f:green]#{conn.player.username} #{message}")
  end

  parse_input_with /ooc (.+)/ do |conn, message|
    message = message.purge_colors
    conn.player.room.transmit("[OOC] #{conn.player.username}: #{message}")
  end

  parse_input_with /general (.+)/ do |conn, message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("([f:cyan]GENERAL[reset]) #{conn.player.username} - [f:white:b]#{message}")
    end
  end

  parse_input_with /trade (.+)/ do |conn, message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("([f:blue]TRADE[reset]) #{conn.player.username} - [f:white:b]#{message}")
    end
  end

  parse_input_with /newb (.+)/ do |conn, message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("([f:green]NEWBIE[reset]) #{conn.player.username} - [f:white:b]#{message}")
    end
  end

  parse_input_with /tell (.+?) (.+)/ do |conn, player_name, message|
    message = message.purge_colors
    other_player = Player.with_username(player_name)
    if other_player.count > 0
      other_player = other_player.first
      if other_player.online?
        Player.connections[other_player.id].each do |other_conn|
          other_conn.send_text("[f:magenta]#{conn.player.username} tells you \"#{message}\"")
        end
        conn.send_text("[f:magenta]You tell #{other_player.username} \"#{message}\"")
      else
        conn.send_text("[f:magenta]#{other_player.username} cannot be found.")
      end
    else
      conn.send_text("[f:magenta]#{player_name.capitalize} is not recognized, are your sure they exist?")
    end
  end

  parse_input_with /server (.+)/ do |conn, message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("[f:yellow:b][SERVER] #{message}")
    end
  end
end