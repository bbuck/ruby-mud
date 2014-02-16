module RoomBuilderHelpers
  def self.room_builder_menu(conn, room)
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

    conn.send_text(text, newline: false, prompt: false)
  end

  def self.edit_exit_menu(conn, room)
    no_room = "\bno room"
    text = <<-MENU

[f:white:b]==== Link Exits ===============================================================
[reset][f:green]
  north -> [f:white:b]##{room.north ? room.north : no_room}
  [reset][f:green]south -> [f:white:b]##{room.south ? room.south : no_room}
  [reset][f:green]east -> [f:white:b]##{room.east ? room.east : no_room}
  [reset][f:green]west -> [f:white:b]##{room.west ? room.west : no_room}
  [reset][f:green]northwest -> [f:white:b]##{room.northwest ? room.northwest : no_room}
  [reset][f:green]northeast -> [f:white:b]##{room.northeast ? room.northeast : no_room}
  [reset][f:green]southwest -> [f:white:b]##{room.southwest ? room.southwest : no_room}
  [reset][f:green]southeast -> [f:white:b]##{room.southeast ? room.southeast : no_room}
  [reset][f:green]up -> [f:white:b]##{room.up ? room.up : no_room}
  [reset][f:green]down -> [f:white:b]##{room.down ? room.down : no_room}

  [reset][f:green]go back - [f:white:b]Return to the main editor

  [reset][f:green]Example: north #10 (links the north exit to 10)

Enter Option >>
    MENU
    conn.send_text(text, newline: false, prompt: false)
  end

  def self.room_quick_info(conn, room)
    # TODO: Check Authorization
    exit_str = room.exit_array.map { |e| e.to_s.capitalize }.join(", ")
    text = <<-INFO
\n\n[f:white:b]==== Quick Room Info ==========================================================
  [reset][f:green]Created At: [f:white:b]#{room.created_at.localtime.strftime(TimeFormats::LONG_WITH_TIME)}
  [reset][f:green]Created By: [f:white:b]#{room.creator.username}

  [reset][f:green]Room ID:    [f:white:b]##{room.id}
  [reset][f:green]Title:      [f:white:b]#{room.name}
  [reset][f:green]Exits:      [f:white:b]#{exit_str}
  [reset][f:green]Players:    [f:white:b]#{room.players_in_room.online.count}
[f:white:b]===============================================================================[reset]
    INFO
    conn.send_text(text)
  end

  def self.edit_room(conn, room)
    # TODO: Check Permissions
    if true
      conn.input_state = :room_builder
      conn.internal_state = {room: room}
      RoomBuilderHelpers.room_builder_menu(conn, room)
    else
      InputManager.unknown_input(conn)
    end
  end
end

InputManager.respond_to :room_builder do

  # --- Catch All ------------------------------------------------------------

  parse_input_with(/\A1\z/) do |conn|
    conn.internal_state[:enter_name] = true
    conn.send_text("[f:green]Enter a new title for this room:", prompt: false)
  end

  parse_input_with(/\A2\z/) do |conn|
    EditorHelpers.open_editor(conn, conn.internal_state[:room], :description, allow_colors: true) do |conn|
      RoomBuilderHelpers.room_builder_menu(conn, conn.internal_state[:room])
    end
  end

  parse_input_with(/\A3\z/) do |conn|
    conn.internal_state[:edit_exits] = true
    RoomBuilderHelpers.edit_exit_menu(conn, conn.internal_state[:room])
  end

  parse_input_with(/\A5\z/) do |conn|
    EditorHelpers.open_editor(conn, conn.internal_state[:room], :script, allow_colors: true) do |conn|
      RoomBuilderHelpers.room_builder_menu(conn, conn.internal_state[:room])
      conn.internal_state[:room]
    end
  end

  parse_input_with(/\A7\z/) do |conn|
    conn.input_state = :standard
    conn.send_text(conn.player.room.display_text(conn.player), newline: false)
  end

  parse_input_with(/go back/) do |conn|
    conn.internal_state.delete(:edit_exits)
    RoomBuilderHelpers.room_builder_menu(conn, conn.internal_state[:room])
  end

  parse_input_with(/(northwest|northeast|southwest|southeast|north|south|east|west|up|down) #?(\d+)/) do |conn, dir, room_id|
    if conn.internal_state[:edit_exits]
      begin
        o_room = Room.find(room_id)
        conn.internal_state[:room].update_attribute(dir.to_sym, room_id)
      rescue ActiveRecord::RecordNotFound => e
        conn.send_text("[f:yellow:b]There is not room with the id ##{room_id}!", prompt: false)
      end
      RoomBuilderHelpers.edit_exit_menu(conn, conn.internal_state[:room])
    else
      RoomBuilderHelpers.room_builder_menu(conn, conn.internal_state[:room])
    end
  end

  parse_input_with(/(.*)/) do |conn, input|
    if conn.internal_state[:enter_name]
      conn.internal_state.delete(:enter_name)
      conn.internal_state[:room].update_attribute(:name, input.strip)
      RoomBuilderHelpers.room_builder_menu(conn, conn.internal_state[:room])
    elsif conn.internal_state[:edit_exits]
      RoomBuilderHelpers.edit_exit_menu(conn, conn.internal_state[:room])
    else
      RoomBuilderHelpers.room_builder_menu(conn, conn.internal_state[:room])
    end
  end
end