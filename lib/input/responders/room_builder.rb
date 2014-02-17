class RoomBuilderResponder < InputResponder
  # --- Template Helpers -----------------------------------------------------

  def send_room_builder_menu(room = nil)
    room = editing_room if room.nil?
    text = <<-MENU

[f:white:b]
+-----------------------------------------------------------------------------+
|   [reset][f:green]Room Builder (v 1.0 by Brandon Buck)[f:white:b]                                      |
+-----------------------------------------------------------------------------+
[reset][f:green]
  = Room ##{room.id} - [f:white:b]#{room.name}

  [f:white:b][1][reset][f:green] Edit Room Name
  [f:white:b][2][reset][f:green] Edit Room Description
  [f:white:b][3][reset][f:green] Edit Room Exits
  [f:white:b][4][reset][f:green] Edit Doors (NYI)
  [f:white:b][5][reset][f:green] Edit Script
  [f:white:b][6][reset][f:green] Delete Room

  [f:white:b][7][reset][f:green] Exit Editor
[f:white:b]
+-----------------------------------------------------------------------------+
[reset][f:green]
Enter Options >>
    MENU
    send_no_prompt_or_newline(text)
  end

  def send_edit_exit_menu(room = nil)
    room = editing_room if room.nil?
    no_room = "\bno room"
    text = <<-MENU
[f:white:b]
==== Link Exits ===============================================================
[reset][f:green]
  north -> [f:white:b]#{room.north ? room.north.name : no_room}[reset]
  [f:green]south -> [f:white:b]#{room.south ? room.south.name : no_room}[reset]
  [f:green]east -> [f:white:b]#{room.east ? room.east.name : no_room}[reset]
  [f:green]west -> [f:white:b]#{room.west ? room.west.name : no_room}[reset]
  [f:green]northwest -> [f:white:b]#{room.northwest.name ? room.northwest : no_room}[reset]
  [f:green]northeast -> [f:white:b]#{room.northeast.name ? room.northeast : no_room}[reset]
  [f:green]southwest -> [f:white:b]#{room.southwest.name ? room.southwest : no_room}[reset]
  [f:green]southeast -> [f:white:b]#{room.southeast.name ? room.southeast : no_room}[reset]
  [f:green]up -> [f:white:b]#{room.up ? room.up.name : no_room}[reset]
  [f:green]down -> [f:white:b]#{room.down ? room.down.name : no_room}[reset]

  [f:green]search <query> - [reset]List up to 10 rooms with a name matching the query.
  [f:green]reset <direction> - [reset]Reset the link at this exit.
  [f:green]go back - [reset]Return to the main editor
  [f:green]help - [reset]Show help with linking exits.

Enter Option >>
    MENU
    send_no_prompt_or_newline(text)
  end

  def send_edit_exit_help
    help = <<-HELP
[f:white:b]
==== Edit Exits Help ==========================================================
[reset][f:green]
  Point a direction to a specific room by specifying the exit followed by the
    room number.
[f:white:b]
    north 10
    south #33
[reset][f:green]
  Clear the room that an exit points to (remove an exit)
[f:white:b]
    reset north
    reset down
[reset][f:green]
  Search for Room IDs by room name (displays up to 10 matches).
[f:white:b]
    search House

===============================================================================
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
    parse_input_with(/\Ago back\z/) do
      clear_mode
      send_room_builder_menu
    end

    parse_input_with(/\Areset (.+)\z/) do |direction|
      direction = direction.downcase.to_sym
      if Room::EXITS.include?(direction)
        editing_room.update_attribute(direction, nil)
        send_no_prompt("[f:green]Removed the link for the #{direction} exit!")
      else
        send_no_prompt("[f:yellow:b]#{direction.to_s.capitalize} is not a valid exit!")
      end
    end

    parse_input_with(/\A(northwest|northeast|southwest|southeast|north|south|east|west|up|down) #?(\d+)\z/) do |direction, room_id|
      begin
        o_room = Room.find(room_id)
        editing_room.update_attribute(direction.to_sym, room_id)
        send_no_prompt("[f:green]Linked #{direction} to room ##{room_id}!")
      rescue ActiveRecord::RecordNotFound => e
        send_no_prompt("[f:yellow:b]There is not room with the id ##{room_id}!")
      end
    end

    parse_input_with(/\Ahelp\z/) do
      send_edit_exit_help
    end

    parse_input_with(/\A.+\z/) do
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
    editor.open_editor(editing_room, :script, allow_colors: true) do |connection|
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