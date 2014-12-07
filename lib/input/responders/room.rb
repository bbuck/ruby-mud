class Input::Responder::Room < Input::Responder::Base
  DEFAULT_ROOM_DESCRIPTION = "This room lacks a description."
  DEFAULT_ROOM_NAME = "This room has not been named."

  DONT_SEE = [
    "There doesn't appear to be anything like that.",
    "You don't see anything like that.",
    "You look around but can't seem to find anything.",
    "You stare at the ground intently expecting to see something."
  ]

  # --- Helpers --------------------------------------------------------------

  def travel(direction)
    direction = direction.to_s.downcase.to_sym
    if current_room.has_exit?(direction)
      if current_room.exit_open?(direction)
        cur_room, new_room = current_room, current_room.send(direction)
        player.update_attribute(:room, new_room)
        new_room.player_enters(player, direction)
        cur_room.player_left(player, direction)
      else
        case current_room.exit_status(direction)
        when :locked
          write("[f:green]You check the door but it's locked.")
        when :unlocked, :closed
          write("[f:green]The door is closed!")
        end
      end
    else
      write("[f:yellow:b]There is no exit #{direction}!")
    end
  end

  def expand_direction(direction)
    Helpers::Exit.expand(direction)
  end

  # --- Look Handlers --------------------------------------------------------

  parse_input_with(/\A(?:look|l) (northeast|ne|northwest|nw|southeast|se|southwest|sw|north|n|south|s|east|e|west|w|up|u|down|d)\z/) do |direction|
    direction = expand_direction(direction)
    if Helpers::Exit.valid?(direction)
      if current_room.has_exit?(direction)
        if current_room.exit_open?(direction)
          new_room = current_room.send(direction)
          write_room_description(new_room)
        else
          write("[f:yellow:b]You can't see through doors!")
        end
      else
        write("[f:yellow:b]There is no exit in that direction!")
      end
    else
      write_unknown_input
    end
  end

  parse_input_with(/\A(?:look|l) (.+)\z/) do |object|
    saw = current_room.player_looks_at(player, object)
    if saw && saw.kind_of?(String)
      write(saw)
    else
      write("[f:green]" + DONT_SEE.sample)
    end
  end

  parse_input_with(/\A(?:look|l)\z/) do
    write_room_description
  end

  # --- Directional Handlers ----------------------------------------------------

  parse_input_with(/\A(northeast|ne|northwest|nw|southeast|se|southwest|sw|north|n|south|s|east|e|west|w|up|u|down|d)\z/i) do |direction|
    direction = expand_direction(direction)
    if Helpers::Exit.valid?(direction)
      travel(direction)
    else
      write_unknown_input
    end
  end

  parse_input_with(/\A(open|close|unlock|lock) (northeast|ne|northwest|nw|southeast|se|southwest|sw|north|n|south|s|east|e|west|w|up|u|down|d)\z/) do |action, direction|
    direction = expand_direction(direction)
    case action
    when "open"
      status = current_room.open_exit(direction)
      case status
      when :success
        write("[f:green]You open the door.")
      when :no_door
        write("[f:green]There is no door there!")
      when :locked
        write("[f:green]You can't open a locked door!")
      when :open
        write("[f:green]The door is already open!")
      when :no_exit
        write("[f:yellow:b]There is no exit in that direction!")
      end
    when "close"
      status = current_room.close_exit(direction)
      case status
      when :success
        write("[f:green]You close the door.")
      when :closed
        write("[f:green]The door is already closed!")
      when :no_door
        write("[f:green]There is no door there!")
      when :no_exit
        write("[f:yellow:b]There is no exit in that direction!")
      end
    when "unlock"
      status = current_room.unlock_exit(direction, player)
      case status
      when :success
        write("[f:green]You unlock the door.")
      when :no_door
        write("[f:green]There is no door there!")
      when :no_lock
        write("[f:green]There is no way to lock this door!")
      when :unlocked
        write("[f:green]The door has already been unlocked!")
      when :open
        write("[f:green]You must close the door first!")
      when :no_exit
        write("[f:yellow:b]There is no exit in that direction!")
      end
    when "lock"
      status = current_room.lock_exit(direction)
      case status
      when :success
        write("[f:green]You lock the door.")
      when :no_door
        write("[f:green]There is no door there!")
      when :no_lock
        write("[f:green]There is no way to lock this door!")
      when :locked
        write("[f:green]The door has already been locked!")
      when :open
        write("[f:green]You must close the door first!")
      when :no_exit
        write("[f:yellow:b]There is no exit in that direction!")
      end
    end
  end
end

Input::Manager.register_responder(:standard, Input::Responder::Room)