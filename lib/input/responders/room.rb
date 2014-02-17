class RoomResponder < InputResponder
  # --- Templates Helpers ----------------------------------------------------

  def send_room_info(room = nil)
    room = current_room if room.nil?
    text = <<-INFO

[f:white:b]
==== Quick Room Info ==========================================================

  [reset][f:green]Created At: [f:white:b]#{room.created_at.localtime.strftime(TimeFormats::LONG_WITH_TIME)}
  [reset][f:green]Created By: [f:white:b]#{room.creator.username}

  [reset][f:green]Room ID:    [f:white:b]##{room.id}
  [reset][f:green]Title:      [f:white:b]#{room.name}
  [reset][f:green]Exits:      [f:white:b]#{exit_str}
  [reset][f:green]Players:    [f:white:b]#{room.players_in_room.online.count}
[f:white:b]
===============================================================================[reset]

    INFO
    send(info)
  end

  # --- Helpers --------------------------------------------------------------

  def travel(direction)
    direction = direction.to_s.downcase.to_sym
    room_method = "#{direction}_room".to_sym
    if current_room.has_exit?(direction)
      cur_room, new_room = current_room, current_room.send(room_method)
      new_room.player_enters(player, direction)
      player.update_attribute(:room, new_room)
      cur_room.player_leaves(player, direction)
    else
      send("[f:yellow:b]There is no exit #{direction}!")
    end
  end

  # --- Look Handlers --------------------------------------------------------

  parse_input_with(/\A(?:look|l) (.+)\z/) do |direction|
    direction = direction.downcase.to_sym
    if Room::EXITS.include?(direction)
      direction = Room::EXITS_EXPANDED[direction] if Room::EXITS_EXPANDED.keys.include?(direction)
      if current_room.has_exit?(direction)
        new_room = current_room.send("#{direction}_room")
        send_room_description(new_room)
      else
        send("[f:yellow:b]There is no exit in that direction!")
      end
    else
      send_unknown_input
    end
  end

  parse_input_with(/\A(?:look|l)\z/) do |conn|
    send_room_description
  end

  # --- Movement Handlers ----------------------------------------------------

  parse_input_with(/\A(?:northeast|ne)\z/) do
    travel(:northeast)
  end

  parse_input_with(/\A(?:northwest|nw)\z/) do
    travel(:northwest)
  end

  parse_input_with(/\A(?:north|n)\z/) do
    travel(:north)
  end

  parse_input_with(/\A(?:southwest|sw)\z/) do
    travel(:southwest)
  end

  parse_input_with(/\A(?:southeast|se)\z/) do
    travel(:southeast)
  end

  parse_input_with(/\A(?:south|s)\z/) do
    travel(:south)
  end

  parse_input_with(/\A(?:east|e)\z/) do
    travel(:east)
  end

  parse_input_with(/\A(?:west|w)\z/) do
    travel(:west)
  end

  parse_input_with(/\A(?:up|u)\z/) do
    travel(:up)
  end

  parse_input_with(/\A(?:down|d)\z/) do
    travel(:down)
  end

  # --- Initiate Room Builder methods ----------------------------------------

  parse_input_with(/@roominfo #?(\d+)/) do |room_id|
    # TODO: Check Authorization
    begin
      room = Room.find(room_id)
      send_room_info
    rescue ActiveRecord::RecordNotFound => e
      send("[f:yellow:b]There is no room with the id ##{room_id}")
    end
  end

  parse_input_with(/@roominfo/) do |conn|
    send_room_info
  end

  parse_input_with(/@dig (.+)/) do |room_name|
    # TODO: Check Authorization
    if room_name.length == 0
      send("[f:yellow:b]You must specify a name for the new room!")
    else
      room = Room.create(name: room_name, description: "This room lacks a description.", creator: conn.player)
      RoomBuilderResponder.new(connection).edit_room(room)
    end
  end

  parse_input_with(/@edit #?(\d+)/) do |room_id|
    # TODO: Check Authorization
    begin
      room = Room.find(room_id)
      RoomBuilderResponder.new(connection).edit_room(room)
    rescue ActiveRecord::RecordNotFound => e
      send("[f:yellow:b]There is no room with the id ##{room_id}")
    end
  end

  parse_input_with(/@edit/) do
    RoomBuilderResponder.new(connection).edit_room(current_room)
  end
end

InputManager.add_responder(:standard, RoomResponder)