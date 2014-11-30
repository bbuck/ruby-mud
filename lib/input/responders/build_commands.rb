module Input
  module Responder
    class BuildCommands < Base
      # --- Templates Helpers ----------------------------------------------------

      def send_room_info(room = current_room)
        exit_str = room.exit_array.join(", ")
        header = Helpers::Text.header_with_title("[f:green]Quick Room Info")
        footer = Helpers::Text.full_line("=")
        text = <<-INFO.strip_heredoc

          [f:white:b]
          #{header}
            [reset][f:green]Created At: [f:white:b]#{room.created_at.localtime.strftime(TimeFormats::LONG_WITH_TIME)}
            [reset][f:green]Created By: [f:white:b]#{room.creator.username}

            [reset][f:green]Room ID:    [f:white:b]##{room.id}
            [reset][f:green]Title:      [f:white:b]#{room.name}
            [reset][f:green]Exits:      [f:white:b]#{exit_str}
            [reset][f:green]Players:    [f:white:b]#{room.players_in_room.online.count}
          [f:white:b]
          #{footer}

        INFO
        send(text)
      end

      # --- Helpers --------------------------------------------------------------

      def create_and_edit_room(room_name)
        room = ::Room.create(name: room_name, description: DEFAULT_ROOM_DESCRIPTION, creator: player)
        create_responder(RoomBuilder).edit_room(room)
      end

      # --- Room Handlers --------------------------------------------------------

      parse_input_with(/\A@room info #?(\d+)\z/) do |room_id|
        if player.can_build?
          begin
            room = ::Room.find(room_id)
            send_room_info(room)
          rescue ActiveRecord::RecordNotFound => e
            send("[f:yellow:b]There is no room with the id ##{room_id}")
          end
        else
          send_not_authorized
        end
      end

      parse_input_with(/\A@room info\z/) do
        if player.can_build?
          send_room_info
        else
          send_not_authorized
        end
      end

      parse_input_with(/\A@room search (.*?)\z/) do |query|
        if player.can_build?
          rooms = ::Room.name_like(query).limit(10)
          if rooms.count > 0
            lines = rooms.map do |room|
              "[f:green]##{room.id} - [f:white:b]#{room.name}"
            end
            str = "\n" + lines.join("\n") + "\n"
            send_no_prompt(str)
          else
            send_no_prompt("[f:yellow:b]No rooms were found matching \"#{query}\"")
          end
        else
          send_not_authorized
        end
      end

      parse_input_with(/\A@dig (.+)\z/) do |room_name|
        if player.can_build?
          create_and_edit_room(room_name)
        else
          send_not_authorized
        end
      end

      parse_input_with(/\A@dig\z/) do
        if player.can_build?
          create_and_edit_room(DEFAULT_ROOM_NAME)
        else
          send_not_authorized
        end
      end

      parse_input_with(/\A@edit room #?(\d+)\z/) do |room_id|
        if player.can_build?
          begin
            room = ::Room.find(room_id)
            create_responder(RoomBuilder).edit_room(room)
          rescue ActiveRecord::RecordNotFound => e
            send("[f:yellow:b]There is no room with the id ##{room_id}")
          end
        else
          send_not_authorized
        end
      end

      parse_input_with(/\A@edit room\z/) do
        if player.can_build?
          create_responder(RoomBuilder).edit_room(current_room)
        else
          send_not_authorized
        end
      end

      # --- NPC Handlers ---------------------------------------------------------

    end
  end
end

Input::Manager.register_responder(:standard, Input::Responder::BuildCommands)