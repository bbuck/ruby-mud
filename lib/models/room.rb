class Room < ActiveRecord::Base
  EXITS = [:north, :south, :east, :west, :northwest, :northeast, :southwest,
           :southeast, :up, :down]

  EXITS_INVERSE = {
    north: :south,
    south: :north,
    east: :west,
    west: :east,
    northwest: :southeast,
    northeast: :southwest,
    southeast: :northwest,
    southwest: :northeast,
    up: :down,
    down: :up
  }

  EXITS_PROPER = {
    north: "the north",
    south: "the south",
    east: "the east",
    west: "the west",
    northwest: "the northwest",
    northeast: "the northeast",
    southwest: "the southwest",
    southeast: "the southeast",
    up: "above",
    down: "below"
  }

  EXITS.each do |exit_name|
    define_method "#{exit_name}_room" do
      if send(exit_name)
        Room.find(send(exit_name))
      else
        nil
      end
    end
  end

  has_many :players_in_room, class_name: "Player"

  class << self
    def engines
      @@engines ||= {}
    end
  end

  def player_appears(player)
    transmit("[f:green]#{player.username} appears magically.")
  end

  def player_enters(player, dir)
    from_dir = EXITS_PROPER[EXITS_INVERSE[dir]]
    transmit("[f:green]#{player.username} enters from #{from_dir}.")
    script_engine.call(:player_entered, player, dir)
    player.update_attributes(room: self)
  end

  def player_leaves(player, dir)
    from_dir = EXITS_PROPER[dir]
    if from_dir == "above"
      transmit("[f:green]#{player.username} leaves up.")
    elsif from_dir == "below"
      transmit("[f:green]#{player.username} leaves #{from_dir}.")
    else
      transmit("[f:green]#{player.username} leaves to #{from_dir}.")
    end
  end

  def transmit(message)
    players_in_room_ids.each do |pid|
      if Player.connections[pid]
        Player.connections[pid].each do |conn|
          conn.send_text(message)
        end
      end
    end
  end

  def display_text(player)
    display = <<-ROOM
\n[f:white:b]#{name}
[reset]--------------------------------------------------------------------------------
[f:green]#{description}

#{exit_string}
    ROOM

    display += "\n#{player_string(player)}" if players_in_room.where("id <> ?", player.id).count > 0
    display
  end

  private

  def script_engine
    @engine ||= begin
      Room.engines[id] ||= begin
        engine = ES::Engine.new
        engine.execute(self.script || "")
        engine
      end
    end
  end

  # --- Text Helpers ----------------------------------------------------------

  def player_string(viewing_player)
    players = []
    players_in_room.where("id <> ?", viewing_player.id).online.each do |player|
      players << "#{player.username} is standing here."
    end
    players.join("\n")
  end

  def exit_string
    has_exits = []
    EXITS.each do |exit_name|
      if send(exit_name)
        has_exits << exit_name
      end
    end

    str = if has_exits.length == 0
      "NO EXITS"
    elsif has_exits.length == 1
      "EXIT TO THE [f:white:b]#{has_exits[0]}[reset][f:red]."
    elsif has_exits.length == 2
      "EXIT TO THE [f:white:b]#{has_exits[0]} [reset][f:red]OR[f:white:b] #{has_exists[1]}[reset][f:red]."
    else
      last = has_exits.pop
      str = has_exits.join("[reset][f:red],[f:white:b] ")
      "EXITS TO THE #{str} [reset][f:red]AND[f:white:b] #{last}[reset][f:red]."
    end
    "[reset][f:red]#{str}"
  end
end