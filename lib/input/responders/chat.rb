class ChatResponder < InputResponder
  # --- Responders -----------------------------------------------------------

  parse_input_with(/\Asay (.+)\z/) do |message|
    message = message.purge_colors
    current_room.transmit("[f:cyan:b]#{player.username} says, \"#{message}\"")
  end

  parse_input_with(/\Ayell (.+)\z/) do |message|
    message = message.purge_colors
    yell = "[f:red:b]#{player.username} yells, \"#{message}\""
    Yell.new(yell, current_room)
  end

  parse_input_with(/\Axme (.+)\z/, /\Axpost (.+)\z/) do |message|
    message = message.purge_colors
    current_room.transmit("[f:green]#{message}")
  end

  parse_input_with(/\Ame (.+)\z/, /\Apost (.+)\z/) do |message|
    message = message.purge_colors
    current_room.transmit("[f:green]#{player.username} #{message}")
  end

  parse_input_with(/\Aooc (.+)\z/) do |message|
    message = message.purge_colors
    current_room.transmit("[OOC] #{player.username}: #{message}")
  end

  parse_input_with(/\Ageneral (.+)\z/) do |message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("([f:cyan]GENERAL[reset]) #{player.username} - [f:white:b]#{message}", prompt: false)
    end
  end

  parse_input_with(/\Atrade (.+)\z/) do |message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("([f:blue]TRADE[reset]) #{player.username} - [f:white:b]#{message}", prompt: false)
    end
  end

  parse_input_with(/\Anewb (.+)\z/) do |message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("([f:green]NEWBIE[reset]) #{player.username} - [f:white:b]#{message}", prompt: false)
    end
  end

  parse_input_with(/\Atell (.+?) (.+)\z/) do |player_name, message|
    message = message.purge_colors
    other_player = Player.with_username(player_name)
    if other_player.count > 0
      other_player = other_player.first
      if other_player.online?
        Player.connections[other_player.id].each do |other_conn|
          other_conn.send_text("[f:magenta]#{player.username} tells you \"#{message}\"", prompt: false)
        end
        send_no_prompt("[f:magenta]You tell #{other_player.username} \"#{message}\"")
      else
        send_no_prompt("[f:magenta]#{other_player.username} cannot be found.")
      end
    else
      send_no_prompt("[f:magenta]#{player_name.capitalize} is not recognized, are your sure they exist?")
    end
  end

  parse_input_with(/\Aserver (.+)\z/) do |message|
    message = message.purge_colors
    Player.connection_list.each do |player_conn|
      player_conn.send_text("[f:yellow:b][SERVER] #{message}", prompt: false)
    end
  end
end

InputManager.add_responder(:standard, ChatResponder)