module Input
  module Responder
    class RoomBuilder < Base
      EXITS_RX = "northwest|northeast|southwest|southeast|north|south|east|west|up|down"

      # --- Template Helpers -----------------------------------------------------

      def send_room_builder_menu(room = nil)
        room = editing_room if room.nil?
        room.reload
        divider = Helpers::Text.full_line("-", "+")
        text = Helpers::View.render("responder.room_builder.main_menu", {room: room, divider: divider})
        send_no_prompt_or_newline(text)
      end

      def send_edit_exit_menu(room = nil)
        room = editing_room if room.nil?
        room.reload
        exit_info = Helpers::Exit.map do |exit_name|
          details = room.exits[exit_name]
          str = "    [f:green]#{exit_name.to_s.capitalize.ljust(9)} -> "
          if room.has_exit?(exit_name)
            spaces = "                 "
            str += "[f:white:b]#{room.send(exit_name).name}"
            if details.has_key?(:door)
              str += if details[:door][:timer] == :never
                "\n#{spaces}[f:green]door does not close automatically"
              else
                "\n#{spaces}[f:green]door closes after #{details[:door][:timer]}"
              end
              if details.has_key?(:lock)
                str += if details[:lock][:timer] == :never
                  "\n#{spaces}[f:green]door does not lock automatically"
                else
                  "\n#{spaces}door locks after #{details[:lock][:timer]}"
                end
              end
            end
          else
            str += "[f:white]no room"
          end
          str
        end
        menu = Helpers::View.render("responder.room_builder.exit_menu", {room: room, exit_info: exit_info.join("\n")})
        send_no_prompt_or_newline(menu)
      end

      def send_edit_exit_help
        send_no_prompt(Helpers::View.render("responder.room_builder.exit_help"))
      end

      def send_edit_npc_menu
        header = Helpers::Text.header_with_title("[f:green]Edit NPCs")
        footer = Helpers::Text.full_line("=")
        menu = <<-MENU.strip_heredoc
          #{header}

          #{footer}
        MENU
        send_no_prompt(menu)
      end

      # --- Helpers --------------------------------------------------------------

      def editing_room
        internal_state[:room]
      end

      def edit_room(room)
        change_input_state(:room_builder)
        self.internal_state = {room: room}
        player.update_attribute(:room, room)
        send_room_builder_menu
      end

      # --- Responders -----------------------------------------------------------

      responders_for_mode :edit_exits do
        parse_input_with(/\Aback\z/) do
          clear_mode
          send_room_builder_menu
        end

        parse_input_with(/\Areset (.+)( here)?\z/) do |direction, here|
          direction = direction.downcase.to_sym
          if Helpers::Exit.valid?(direction)
            editing_room.remove_exit(direction, {unlink_other: here.nil?})
            send_no_prompt("[f:green]Removed the link for the #{direction} exit!")
          else
            send_no_prompt("[f:yellow:b]#{direction.to_s.capitalize} is not a valid exit!")
          end
          send_edit_exit_menu
        end

        parse_input_with(/\Asearch (.+)?\z/) do |query|
          rooms = ::Room.name_like(query).limit(10)
          room_str = rooms.map do |room|
            "##{room.id} - [f:white:b]#{room.name}[reset]"
          end

          send_no_prompt("Search results for \"#{query}\":")
          send_no_prompt(room_str.join("\n") + "\n")
        end

        parse_input_with(/\A(#{EXITS_RX}) #?(\d+)( here)?\z/) do |direction, room_id, here|
          if ::Room.where(id: room_id).count > 0
            editing_room.add_exit(direction.to_sym, room_id, {link_other: here.nil?})
            send_no_prompt("[f:green]Linked #{direction} to room ##{room_id}!")

            send_edit_exit_menu
          else
            send_no_prompt("[f:yellow:b]There is not room with the id ##{room_id}!")
          end
        end

        parse_input_with(/\Ahelp\z/) do
          send_edit_exit_help
        end

        parse_input_with(/\A(close|lock) (#{EXITS_RX}) after ([\dwMwdhms]+)( here)?\z/) do |action, direction, timer, here|
          if action == "close"
            direction = direction.to_sym
            if current_room.has_exit?(direction)
              current_room.add_door_to(direction, timer, {add_to_other: here.nil?})
              send_no_prompt("[f:green]Added a door to #{direction}")
            else
              send_no_prompt("[f:green]This room doesn't have that exit!")
            end
          else
            direction = direction.to_sym
            if current_room.has_exit?(direction)
              current_room.add_lock_to(direction, timer, {add_to_other: here.nil?})
              send_no_prompt("[f:green]Added a lock to #{direction}")
            else
              send_no_prompt("[f:green]This room doesn't have that exit!")
            end
          end

          send_edit_exit_menu
        end

        parse_input_with(/\A(lock|close) (#{EXITS_RX})( here)?\z/) do |action, direction, here|
          if action == "close"
            direction = direction.to_sym
            if current_room.has_exit?(direction)
              current_room.add_door_to(direction, :never, {add_to_other: here.nil?})
              send_no_prompt("[f:green]Added a door to #{direction}")
            else
              send_no_prompt("[f:green]This room doesn't have that exit!")
            end
          else
            direction = direction.to_sym
            if current_room.has_exit?(direction)
              current_room.add_lock_to(direction, :never, {add_to_other: here.nil?})
              send_no_prompt("[f:green]Added a lock to #{direction}")
            else
              send_no_prompt("[f:green]This room doesn't have that exit!")
            end
          end

          send_edit_exit_menu
        end

        parse_input_with(/\A(unlock|open) (#{EXITS_RX})( here)?\z/) do |action, direction, here|
          direction = direction.to_sym
          if current_room.has_exit?(direction)
            if action == "unlock"
              current_room.remove_lock_from(direction, {remove_from_other: here.nil?})
              send_no_prompt("[f:green]Removed the door and lock from #{direction}")
            elsif action == "open"
              current_room.remove_door_from(direction, {remove_from_other: here.nil?})
              send_no_prompt("[f:green]Removed the door from #{direction}")
            end

            send_edit_exit_menu
          else
            send_no_prompt("[f:green]This room doesn't have that exit!")
          end
        end

        parse_input_with(/\A.*\z/) do
          send_edit_exit_menu
        end
      end

      responders_for_mode :enter_room_name do
        parse_input_with(/\A(.+)\z/) do |new_name|
          clear_mode
          editing_room.update_attribute(:name, new_name.strip)
          send_room_builder_menu
        end
      end

      parse_input_with(/\A1\z/) do
        change_mode(:enter_room_name)
        send_no_prompt("[f:green]Enter a new title for this room:")
      end

      parse_input_with(/\A2\z/) do
        create_responder(Editor).open_editor(editing_room, :description, allow_colors: true) do
          create_responder(RoomBuilder).send_room_builder_menu
        end
      end

      parse_input_with(/\A3\z/) do
        change_mode(:edit_exits)
        send_edit_exit_menu
      end

      parse_input_with(/\A5\z/) do
        create_responder(Editor).open_editor(editing_room, :script, syntax: true) do
          create_responder(RoomBuilder).send_room_builder_menu
        end
      end

      parse_input_with(/\A7\z/) do
        change_input_state(:standard)
        send_room_description
      end

      parse_input_with(/\A.+\z/) do
        send_room_builder_menu
      end
    end
  end
end

Input::Manager.register_responder(:room_builder, Input::Responder::RoomBuilder)