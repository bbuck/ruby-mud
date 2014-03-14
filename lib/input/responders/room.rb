class RoomResponder < InputResponder
  DEFAULT_ROOM_DESCRIPTION = "This room lacks a description."
  DEFAULT_ROOM_NAME = "This room has not been named."

  DONT_SEE = [
    "There doesn't appear to be anything like that.",
    "You don't see anything like that.",
    "You look around but can't seem to find anything.",
    "You stare at the ground intently expecting to see something."
  ]

  # --- Templates Helpers ----------------------------------------------------

  def send_room_info(room = nil)
    room = current_room if room.nil?
    exit_str = room.exit_array.join(", ")
    header = TextHelpers.header_with_title("[f:green]Quick Room Info")
    footer = TextHelpers.full_line("=")
    text = <<-INFO

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

  def travel(direction)
    direction = direction.to_s.downcase.to_sym
    if current_room.has_exit?(direction)
      if current_room.exit_open?(direction)
        cur_room, new_room = current_room, current_room.send(direction)
        new_room.player_enters(player, direction)
        player.update_attribute(:room, new_room)
        cur_room.player_leaves(player, direction)
      else
        case current_room.exit_status(direction)
        when :locked
          send("[f:green]You check the door but it's locked.")
        when :unlocked, :closed
          send("[f:green]The door is closed!")
        end
      end
    else
      send("[f:yellow:b]There is no exit #{direction}!")
    end
  end

  def expand_direction(direction)
    ExitHelpers.expand(direction)
  end

  def create_and_edit_room(room_name)
    room = Room.create(name: room_name, description: DEFAULT_ROOM_DESCRIPTION, creator: player)
    RoomBuilderResponder.new(connection).edit_room(room)
  end

  # --- Look Handlers --------------------------------------------------------

  parse_input_with(/\A(?:look|l) (northeast|ne|northwest|nw|southeast|se|southwest|sw|north|n|south|s|east|e|west|w|up|u|down|d)\z/) do |direction|
    direction = expand_direction(direction)
    if ExitHelpers.valid_exit?(direction)
      if current_room.has_exit?(direction)
        new_room = current_room.send(direction)
        send_room_description(new_room)
      else
        send("[f:yellow:b]There is no exit in that direction!")
      end
    else
      send_unknown_input
    end
  end

  parse_input_with(/\A(?:look|l) (.+)\z/) do |object|
    saw = current_room.player_looks_at(player, object)
    if saw
      send(saw)
    else
      send("[f:green]" + DONT_SEE.sample)
    end
  end

  parse_input_with(/\A(?:look|l)\z/) do
    send_room_description
  end

  # --- Directional Handlers ----------------------------------------------------

  parse_input_with(/\A(northeast|ne|northwest|nw|southeast|se|southwest|sw|north|n|south|s|east|e|west|w|up|u|down|d)\z/i) do |direction|
    direction = expand_direction(direction)
    if ExitHelpers.valid_exit?(direction)
      travel(direction)
    else
      send_unknown_input
    end
  end

  parse_input_with(/\A(open|close|unlock|lock) (northeast|ne|northwest|nw|southeast|se|southwest|sw|north|n|south|s|east|e|west|w|up|u|down|d)\z/) do |action, direction|
    direction = expand_direction(direction)
    case action
    when "open"
      status = current_room.open_exit(direction)
      case status
      when :success
        send("[f:green]You open the door.")
      when :no_door
        send("[f:green]There is no door there!")
      when :locked
        send("[f:green]You can't open a locked door!")
      when :open
        send("[f:green]The door is already open!")
      when :no_exit
        send("[f:yellow:b]There is no exit in that direction!")
      end
    when "close"
      status = current_room.close_exit(direction)
      case status
      when :success
        send("[f:green]You close the door.")
      when :closed
        send("[f:green]The door is already closed!")
      when :no_door
        send("[f:green]There is no door there!")
      when :no_exit
        send("[f:yellow:b]There is no exit in that direction!")
      end
    when "unlock"
      status = current_room.unlock_exit(direction, player)
      case status
      when :success
        send("[f:green]You unlock the door.")
      when :no_door
        send("[f:green]There is no door there!")
      when :no_lock
        send("[f:green]There is no way to lock this door!")
      when :unlocked
        send("[f:green]The door has already been unlocked!")
      when :open
        send("[f:green]You must close the door first!")
      when :no_exit
        send("[f:yellow:b]There is no exit in that direction!")
      end
    when "lock"
      status = current_room.lock_exit(direction)
      case status
      when :success
        send("[f:green]You lock the door.")
      when :no_door
        send("[f:green]There is no door there!")
      when :no_lock
        send("[f:green]There is no way to lock this door!")
      when :locked
        send("[f:green]The door has already been locked!")
      when :open
        send("[f:green]You must close the door first!")
      when :no_exit
        send("[f:yellow:b]There is no exit in that direction!")
      end
    end
  end

  parse_input_with

  # --- Initiate Room Builder methods ----------------------------------------

  parse_input_with(/\A@room info #?(\d+)\z/) do |room_id|
    if player.can_build?
      begin
        room = Room.find(room_id)
        send_room_info(room)
      rescue ActiveRecord::RecordNotFound => e
        send("[f:yellow:b]There is no room with the id ##{room_id}")
      end
    else
      send_not_authorized
    end
  end

  parse_input_with(/\A@room info\z/) do |conn|
    if player.can_build?
      send_room_info
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
        room = Room.find(room_id)
        RoomBuilderResponder.new(connection).edit_room(room)
      rescue ActiveRecord::RecordNotFound => e
        send("[f:yellow:b]There is no room with the id ##{room_id}")
      end
    else
      send_not_authorized
    end
  end

  parse_input_with(/\A@edit room\z/) do
    if player.can_build?
      RoomBuilderResponder.new(connection).edit_room(current_room)
    else
      send_not_authorized
    end
  end
end

InputManager.add_responder(:standard, RoomResponder)