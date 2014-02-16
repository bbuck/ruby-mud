module RoomMovementHelpers
  def self.travel(conn, dir)
    dir = dir.to_s.downcase.to_sym
    method = "#{dir}_room".to_sym
    if conn.player.room.has_exit?(dir)
      cur_room, new_room = conn.player.room, conn.player.room.send(method)
      new_room.player_enters(conn.player, dir)
      cur_room.player_leaves(conn.player, dir)
    else
      conn.send_text("[f:yellow:b]There is no exit #{dir}!")
    end
  end
end

InputManager.respond_to :standard do
  # --- Look Handlers --------------------------------------------------------

  parse_input_with(/\A(?:look|l) (.+)\z/) do |conn, dir|
    dir = dir.downcase.to_sym
    dir = Room::EXITS_EXPANDED[dir] if Room::EXITS_EXPANDED.keys.include?(dir)
    if Room::EXITS.include?(dir)
      if conn.player.room.has_exit?(dir)
        conn.send_text(conn.player.room.send("#{dir}_room").display_text(conn.player), newline: false)
      else
        conn.send_text("[f:yellow:b]There is no exit in that direction!")
      end
    else
      InputManager.unknown_input(conn)
    end
  end

  parse_input_with(/\A(?:look|l)\z/) do |conn|
    conn.send_text(conn.player.room.display_text(conn.player), newline: false)
  end

  # --- Movement Handlers ----------------------------------------------------

  parse_input_with(/\A(?:northeast|ne)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :northeast)
  end

  parse_input_with(/\A(?:northwest|nw)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :northwest)
  end

  parse_input_with(/\A(?:north|n)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :north)
  end

  parse_input_with(/\A(?:southwest|sw)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :southwest)
  end

  parse_input_with(/\A(?:southeast|se)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :southeast)
  end

  parse_input_with(/\A(?:south|s)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :south)
  end

  parse_input_with(/\A(?:east|e)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :east)
  end

  parse_input_with(/\A(?:west|w)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :west)
  end

  parse_input_with(/\A(?:up|u)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :up)
  end

  parse_input_with(/\A(?:down|d)\z/) do |conn|
    RoomMovementHelpers.travel(conn, :down)
  end

  # --- Initiate Room Builder methods ----------------------------------------

  parse_input_with(/@roominfo #?(\d+)/) do |conn, room_id|
    # TODO: Check Authorization
    begin
      room = Room.find(room_id)
      RoomBuilderHelpers.room_quick_info(conn, room)
    rescue ActiveRecord::RecordNotFound => e
      conn.send_text("[f:yellow:b]There is no room with the id ##{room_id}")
    end
  end

  parse_input_with(/@roominfo/) do |conn|
    RoomBuilderHelpers.room_quick_info(conn, conn.player.room)
  end

  parse_input_with(/@dig (.+)/) do |conn, room_name|
    # TODO: Check Authorization
    if room_name.length == 0
      conn.send_text("[f:yellow:b]You must specify a name for the new room!")
    else
      room = Room.create(name: room_name, description: "This room lacks a description.", creator: conn.player)
      RoomBuilderHelpers.edit_room(conn, room)
    end
  end

  parse_input_with(/@edit #?(\d+)/) do |conn, room_id|
    # TODO: Check Authorization
    begin
      room = Room.find(room_id)
      RoomBuilderHelpers.edit_room(conn, room)
    rescue ActiveRecord::RecordNotFound => e
      conn.send_text("[f:yellow:b]There is no room with the id ##{room_id}")
    end
  end

  parse_input_with(/@edit/) do |conn|
    RoomBuilderHelpers.edit_room(conn, conn.player.room)
  end
end