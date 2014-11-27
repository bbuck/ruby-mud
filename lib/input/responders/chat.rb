class ChatResponder < InputResponder
  # --- Helpers --------------------------------------------------------------

  def send_to_everyone(message)
    Player.each_connection do |other_connection|
      other_connection.send_text(message, prompt: false)
    end
  end

  # --- Responders -----------------------------------------------------------

  parse_input_with(/\Asay (.+)\z/) do |message|
    message = message.purge_colors
    send_no_prompt(ChannelFormatter.format(:say_from, {"%M" => message}))
    chan_text = ChannelFormatter.format(:say_to, {"%N" => player.username, "%M" => message})
    current_room.player_transmit(chan_text, player, message, exclude: player)
  end

  parse_input_with(/\Ayell (.+)\z/) do |message|
    message = message.purge_colors
    yell = ChannelFormatter.format(:yell, {"%N" => player.username, "%M" => message})
    Yell.new(yell, current_room)
  end

  parse_input_with(/\Axme (.+)\z/, /\Axpost (.+)\z/) do |message|
    message = message.purge_colors
    current_room.transmit(ChannelFormatter.format(:xpost, {"%M" => message}))
  end

  parse_input_with(/\Ame (.+)\z/, /\Apost (.+)\z/) do |message|
    message = message.purge_colors
    current_room.transmit(ChannelFormatter.format(:post, {"%N" => player.username, "%M" => message}))
  end

  parse_input_with(/\Aooc (.+)\z/) do |message|
    message = message.purge_colors
    current_room.transmit(ChannelFormatter.format(:ooc, {"%N" => player.username, "%M" => message}))
  end

  parse_input_with(/\Ageneral (.+)\z/) do |message|
    message = message.purge_colors
    send_to_everyone(ChannelFormatter.format(:general, {"%N" => player.display_name, "%M" => message}))
  end

  parse_input_with(/\Atrade (.+)\z/) do |message|
    message = message.purge_colors
    send_to_everyone(ChannelFormatter(:trade, {"%N" => player.display_name, "%M" => message}))
  end

  parse_input_with(/\Anewb (.+)\z/) do |message|
    message = message.purge_colors
    send_to_everyone(ChannelFormatter.format(:newbie, {"%N" => player.display_name, "%M" => message}))
  end

  parse_input_with(/\Atell (.+?) (.+)\z/) do |player_name, message|
    message = message.purge_colors
    other_player = Player.with_username(player_name)
    if other_player.count > 0
      other_player = other_player.first
      if other_player.online?
        Player.connections[other_player.id].each do |other_conn|
          other_conn.send_text(ChannelFormatter.format(:tell_to, {"%M" => player.username, "%M" => message}))
        end
        send_no_prompt(ChannelFormatter.format(:tell_from, {"%N" => other_player.username, "%M" => message}))
      else
        send_no_prompt("[f:magenta]#{other_player.username} cannot be found.")
      end
    else
      send_no_prompt("[f:magenta]#{player_name.capitalize} is not recognized, are your sure they exist?")
    end
  end

  parse_input_with(/\Aserver (.+)\z/) do |message|
    if player.can_administrate?
      send_to_everyone(ChannelFormatter.format(:server, {"%M" => message}))
    else
      send_not_authorized
    end
  end
end

InputManager.add_responder(:standard, ChatResponder)