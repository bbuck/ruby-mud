module Input
  module Responder
    class Chat < Base
      # --- Helpers --------------------------------------------------------------

      def write_to_everyone(message)
        ::Player.each_tcp_connection do |other_connection|
          other_connection.write(message, prompt: false)
        end
      end

      def format_channel(*args)
        Game::ChannelFormatter.format(*args)
      end

      # --- Responders -----------------------------------------------------------

      parse_input_with(/\Asay (.+)\z/) do |message|
        message = message.purge_colors
        write_without_prompt(format_channel(:say_from, {"%M" => message}))
        chan_text = format_channel(:say_to, {"%N" => player.username, "%M" => message})
        current_room.player_transmit(chan_text, player, message, exclude: player)
      end

      parse_input_with(/\Ayell (.+)\z/) do |message|
        yell = format_channel(:yell, {"%N" => player.username, "%M" => message.purge_colors})
        Game::Yell.new(yell, current_room)
      end

      parse_input_with(/\Axme (.+)\z/, /\Axpost (.+)\z/) do |message|
        current_room.transmit(format_channel(:xpost, {"%M" => message.purge_colors}))
      end

      parse_input_with(/\Ame (.+)\z/, /\Apost (.+)\z/) do |message|
        current_room.transmit(format_channel(:post, {"%N" => player.username, "%M" => message.purge_colors}))
      end

      parse_input_with(/\Aooc (.+)\z/) do |message|
        current_room.transmit(format_channel(:ooc, {"%N" => player.username, "%M" => message.purge_colors}))
      end

      parse_input_with(/\Ageneral (.+)\z/) do |message|
        write_to_everyone(format_channel(:general, {"%N" => player.display_name, "%M" => message.purge_colors}))
      end

      parse_input_with(/\Atrade (.+)\z/) do |message|
        write_to_everyone(format_channel(:trade, {"%N" => player.display_name, "%M" => message.purge_colors}))
      end

      parse_input_with(/\Anewb (.+)\z/) do |message|
        write_to_everyone(format_channel(:newbie, {"%N" => player.display_name, "%M" => message.purge_colors}))
      end

      parse_input_with(/\Atell (.+?) (.+)\z/) do |player_name, message|
        message = message.purge_colors
        other_player = ::Player.with_username(player_name)
        if other_player.count > 0
          other_player = other_player.first
          if other_player.online?
            other_player.write(format_channel(:tell_to, {"%N" => player.username, "%M" => message}))
            write_without_prompt(format_channel(:tell_from, {"%N" => other_player.username, "%M" => message}))
          else
            write_without_prompt("[f:magenta]#{other_player.username} cannot be found.")
          end
        else
          write_without_prompt("[f:magenta]#{player_name.capitalize} is not recognized, are your sure they exist?")
        end
      end

      parse_input_with(/\Aserver (.+)\z/) do |message|
        if player.can_administrate?
          write_to_everyone(format_channel(:server, {"%M" => message}))
        else
          write_not_authorized
        end
      end
    end
  end
end

Input::Manager.register_responder(:standard, Input::Responder::Chat)