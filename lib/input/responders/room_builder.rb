class RoomBuilderResponder < InputResponder
  EXITS_RX = "northwest|northeast|southwest|southeast|north|south|east|west|up|down"

  # --- Template Helpers -----------------------------------------------------

  def send_room_builder_menu(room = nil)
    room = editing_room if room.nil?
    room.reload
    text = <<-MENU

[f:white:b]
+-----------------------------------------------------------------------------+
|   [f:green]Room Builder (v 1.0 by Brandon Buck)[f:white:b]                                      |
+-----------------------------------------------------------------------------+
[f:green]
  = Room ##{room.id} - [f:white:b]#{room.name}

  [f:white:b][1][f:green] Edit Room Name
  [f:white:b][2][f:green] Edit Room Description
  [f:white:b][3][f:green] Edit Room Exits
  [f:white:b][4][f:green] Edit Doors (NYI)
  [f:white:b][5][f:green] Edit Script
  [f:white:b][6][f:green] Delete Room

  [f:white:b][7][f:green] Exit Editor
[f:white:b]
+-----------------------------------------------------------------------------+
[f:green]
Enter Option >>
    MENU
    send_no_prompt_or_newline(text)
  end

  def send_edit_exit_menu(room = nil)
    room = editing_room if room.nil?
    room.reload
    exit_info = ExitHelpers.map_exits do |exit_name|
      details = room.exits[exit_name]
      str = "  [f:green]#{exit_name.to_s.capitalize} -> "
      if room.has_exit?(exit_name)
        spaces = " " * str.purge_colors.length
        str += "[f:white:b]#{room.send(exit_name).name}"
        if details.has_key?(:door)
          str += "\n[f:green]#{spaces}door closes after #{details[:door][:timer]}"
          if details.has_key?(:lock)
            str += "\n#{spaces}door locks after #{details[:lock][:timer]}"
          end
        end
      else
        str += "[f:white]no room"
      end
      str
    end
    exit_info = exit_info.join("\n")
    header = TextHelpers.header_with_title("[f:green]Edit Exits")
    footer = TextHelpers.full_line("=")
    text = <<-MENU

#{header}
[f:green]
  = Room ##{room.id} - [f:white:b]#{room.name}

#{exit_info}

  [f:green]help - [reset]Show help with linking exits.
  [f:green]back - [reset]Return to the main editor

[f:white:b]#{footer}[f:green]

Enter Option >>
    MENU
    send_no_prompt_or_newline(text)
  end

  def send_edit_exit_help
    header = TextHelpers.header_with_title("[f:green]Edit Exits Help")
    footer = TextHelpers.full_line("=")
    help = <<-HELP

#{header}
[f:green]
  Point a direction to a specific room by specifying the exit followed by the
    room number.
[f:white:b]
    north 10
    south #33
[f:green]
  Clear the room that an exit points to (remove an exit)
[f:white:b]
    reset north
    reset down
[f:green]
  Search for Room IDs by room name (displays up to 10 matches).
[f:white:b]
    search House
[f:green]
  Add a door to an exit that automatically closes after a given interval (leave
    off the interval if you don't want it to automatically close).
[f:white:b]
    close north after 10m
    close south
[f:green]
  Remove a door and lock from an exit.
[f:white:b]
    open north
[f:green]
  Add a lock to an exit that automatically locks after a given interval (leave
    off the interval if you don't want it to automatically lock). Adding a
    lock adds a door that never closes automatically.
[f:white:b]
    lock north after 10m
    lock south
[f:green]
  Remove a lock from an exit.
[f:white:b]
    unlock east

[f:white:b]#{footer}
    HELP
    send_no_prompt(help)
  end

  # --- Helpers --------------------------------------------------------------

  def editing_room
    internal_state[:room]
  end

  def edit_room(room)
    # TODO: Check Permissions
    if true
      change_input_state(:room_builder)
      self.internal_state = {room: room}
      player.update_attribute(:room, room)
      send_room_builder_menu
    else
      InputManager.unknown_input(conn)
    end
  end

  # --- Responders -----------------------------------------------------------

  responders_for_mode :edit_exits do
    parse_input_with(/\Aback\z/) do
      clear_mode
      send_room_builder_menu
    end

    parse_input_with(/\Areset (.+)\z/) do |direction|
      direction = direction.downcase.to_sym
      if ExitHelpers.valid_exit?(direction)
        editing_room.remove_exit(direction)
        send_no_prompt("[f:green]Removed the link for the #{direction} exit!")
      else
        send_no_prompt("[f:yellow:b]#{direction.to_s.capitalize} is not a valid exit!")
      end
    end

    parse_input_with(/\Asearch (.+)\z/) do |query|
      rooms = Room.name_like(query).limit(10)
      room_str = rooms.map do |room|
        "##{room.id} - [f:white:b]#{room.name}[reset]"
      end

      send_no_prompt("Search results for \"#{query}\":")
      send_no_prompt(room_str.join("\n"))
    end

    parse_input_with(/\A(#{EXITS_RX}) #?(\d+)\z/) do |direction, room_id|
      if Room.where(id: room_id).count > 0
        editing_room.add_exit(direction.to_sym, room_id)
        send_no_prompt("[f:green]Linked #{direction} to room ##{room_id}!")
      else
        send_no_prompt("[f:yellow:b]There is not room with the id ##{room_id}!")
      end
    end

    parse_input_with(/\Ahelp\z/) do
      send_edit_exit_help
    end

    parse_input_with(/\A(close|lock) (#{EXITS_RX}) after ([\dwMwdhms]+)\z/) do |action, direction, timer|
      if action == "close"
        direction = direction.to_sym
        if current_room.has_exit?(direction)
          current_room.add_door_to(direction, timer)
          send_no_prompt("[f:green]Added a door to #{direction}")
        else
          send_no_prompt("[f:green]This room doesn't have that exit!")
        end
      else
        direction = direction.to_sym
        if current_room.has_exit?(direction)
          current_room.add_lock_to(direction, timer)
          send_no_prompt("[f:green]Added a lock to #{direction}")
        else
          send_no_prompt("[f:green]This room doesn't have that exit!")
        end
      end
    end

    parse_input_with(/\A(lock|close) (#{EXITS_RX})\z/) do |action, direction|
      if action == "close"
        direction = direction.to_sym
        if current_room.has_exit?(direction)
          current_room.add_door_to(direction, :never)
          send_no_prompt("[f:green]Added a door to #{direction}")
        else
          send_no_prompt("[f:green]This room doesn't have that exit!")
        end
      else
        direction = direction.to_sym
        if current_room.has_exit?(direction)
          current_room.add_lock_to(direction, :never)
          send_no_prompt("[f:green]Added a lock to #{direction}")
        else
          send_no_prompt("[f:green]This room doesn't have that exit!")
        end
      end
    end

    parse_input_with(/\A(unlock|open) (#{EXITS_RX})\z/) do |action, direction|
      direction = direction.to_sym
      if current_room.has_exit?(direction)
        if action == "unlock"
          current_room.remove_lock_from(direction)
          send_no_prompt("[f:green]Removed the door and lock from #{direction}")
        elsif action == "open"
          current_room.remove_door_from(direction)
          send_no_prompt("[f:green]Removed the door from #{direction}")
        end
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
    editor = EditorResponder.new(connection)
    editor.open_editor(editing_room, :description, allow_colors: true) do |connection|
      RoomBuilderResponder.new(connection).send_room_builder_menu
    end
  end

  parse_input_with(/\A3\z/) do
    change_mode(:edit_exits)
    send_edit_exit_menu
  end

  parse_input_with(/\A5\z/) do
    editor = EditorResponder.new(connection)
    editor.open_editor(editing_room, :script, syntax: true) do |connection|
      RoomBuilderResponder.new(connection).send_room_builder_menu
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

InputManager.add_responder(:room_builder, RoomBuilderResponder)