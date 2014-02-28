class Room < ActiveRecord::Base
  ExitHelpers.each_exit do |exit_name|
    define_method exit_name do
      if exits.has_key?(exit_name)
        Room.find(exits[exit_name][:destination])
      else
        nil
      end
    end
  end

  serialize :exits, Hash

  has_many :players_in_room, class_name: "Player"
  belongs_to :creator, class_name: "Player"

  scope :name_like, ->(name) { where("name ILIKE ?", "%#{name}%") }

  class << self
    def engines
      @engines ||= {}
    end
  end

  # --- Player Actions -------------------------------------------------------

  def player_appears(player)
    transmit("[f:green]#{player.display_name} appears magically.")
  end

  def player_enters(player, dir)
    from_dir = ExitHelpers.proper(ExitHelpers.inverse(dir))
    transmit("[f:green]#{player.display_name} [f:green]enters from #{from_dir}.")
    player.connection.send_text(display_text(player), newline: false)
    script_engine.call(:player_entered, player, ExitHelpers.inverse(dir))
  end

  def player_leaves(player, dir)
    from_dir = ExitHelpers.proper(dir)
    text = "[f:green]#{player.display_name} [f:green]"
    if from_dir == "above"
      text += "leaves up."
    elsif from_dir == "below"
      text += "leaves #{from_dir}."
    else
      text += "leaves to #{from_dir}."
    end
    transmit(text)
    script_engine.call(:player_leaves, player, dir)
  end

  def player_looks_at(player, object)
    if players_in_room.with_username(object).count > 0
      players_in_room.with_username(object).first.display_description
    else
      script_engine.call(:player_looks_at, player, object)
    end
  end

  # --- Helpers --------------------------------------------------------------

  def update_attributes(map)
    super
    reload_engine if map.has_key?(:script)
  end

  def update_attribute(prop, val)
    super
    reload_engine if prop == :script
  end

  def remove_exit(dir, options = {})
    if has_exit?(dir)
      if options[:unlink_other]
        other_room = send(dir)
        other_room.remove_exit(ExitHelpers.inverse(dir))
      end
      exits.delete(dir)
      save
    end
  end

  def add_exit(dir, destination, options = {})
    if ExitHelpers.valid_exit?(dir)
      new_exit = exits[dir] = { destination: (destination.kind_of?(Room) ? destination.id : destination) }
      if options[:door]
        new_exit[:door] = { open: false, timer: options[:door], close_at: nil }
      end
      if options[:lock]
        unless new_exit.has_key?(:door)
          new_exit[:door] = { open: false, timer: :never, close_at: nil }
        end
        # TODO: Add Key ID when items are implemented
        new_exit[:lock] = { unlocked: false, timer: options[:lock], lock_at: nil, consume_key: false }
      end
      save
      if options[:link_opposite]
        other_room = (destination.kind_of?(Room) ? destination : Room.find(destination))
        other_room.add_exit(ExitHelpers.inverse(dir), self.id)
      end
    end
  end

  def open_exit(dir, open_opposite = true)
    if has_exit?(dir)
      door, lock = exits[dir][:door], exits[dir][:lock]
      return :no_door unless door.present?
      return :locked if lock.present? && !lock[:unlocked]
      return :open if door[:open]
      door[:open] = true
      unless door[:timer] == :never
        door[:close_at] = Time.now + door[:timer].interval_value
      end
      save
    else
      return :no_exit
    end
    send(dir).open_exit(ExitHelpers.inverse(dir), false) if open_opposite
    :success
  end

  def add_door_to(direction, timer, options = {})
    if has_exit?(direction)
      exits[direction.to_sym][:door] = { open: false, timer: timer, close_at: nil }
      save
      if options[:add_to_link]
        send(direction).add_door_to(ExitHelpers.inverse(direction), timer)
      end
    end
  end

  def add_lock_to(direction, timer, options = {})
    if has_exit?(direction)
      direction = direction.to_sym
      add_door_to(direction, :never) unless exits[direction][:door].present?
      exits[direction][:lock] = { unlocked: false, timer: timer, lock_at: nil }
      save
      if options[:add_to_link]
        send(direction).add_lock_to(ExitHelpers.inverse(direction), timer)
      end
    end
  end

  def remove_lock_from(direction, options = {})
    if has_exit?(direction)
      exits[direction.to_sym].delete(:lock)
      save
      if options[:remove_from_link]
        send(direction).remove_lock_from(ExitHelpers.inverse(direction))
      end
    end
  end

  def remove_door_from(direction, options = {})
    if has_exit?(direction)
      direction = direction.to_sym
      exits[direction].delete(:door)
      exits[direction].delete(:lock)
      save
      if options[:remove_from_link]
        send(direction).remove_door_from(ExitHelpers.inverse(direction))
      end
    end
  end

  def close_exit(dir, close_opposite = true)
    if has_exit?(dir)
      door = exits[dir][:door]
      return :no_door unless door.present?
      return :closed if !door[:open]
      door[:open] = false
      door[:close_at] = nil
      save
    else
      return :no_exit
    end
    send(dir).close_exit(ExitHelpers.inverse(dir), false)
    :success
  end

  def unlock_exit(dir, player, unlock_opposite = true)
    if has_exit?(dir)
      door, lock = exits[dir][:door], exits[dir][:lock]
      return :no_door unless door.present?
      return :no_lock unless lock.present?
      return :open if door[:open]
      return :unlocked if lock[:unlocked]
      lock[:unlocked] = true
      unless lock[:timer] == :never
        lock[:lock_at] = Time.now + lock[:timer].interval_value
      end
      save
    else
      :no_exit
    end
    send(dir).unlock_exit(ExitHelpers.inverse(dir), nil, false) if unlock_opposite
    :success
  end

  def lock_exit(dir, lock_opposite = true)
    if has_exit?(dir)
      door, lock = exits[dir][:door], exits[dir][:lock]
      return :no_door unless door.present?
      return :no_lock unless lock.present?
      return :open if door[:open]
      return :locked if !lock[:unlocked]
      lock[:unlocked] = false
      lock[:lock_at] = nil
      save
    else
      :no_exit
    end
    send(dir).lock_exit(ExitHelpers.inverse(dir), false) if lock_opposite
    :success
  end

  def exit_status(dir)
    if has_exit?(dir)
      door, lock = exits[dir][:door], exits[dir][:lock]
      if door.present?
        return :open if door[:open]
        if lock.present?
          lock[:unlocked] ? :unlocked : :locked
        else
          :closed
        end
      else
        :open
      end
    else
      :no_exit
    end
  end

  def exit_open?(dir)
    exit_status(dir) == :open
  end

  def has_exit?(dir)
    exits.has_key?(dir)
  end

  def transmit(message, options = {})
    players_in_room.online.ids.each do |pid|
      exclude_player = false
      if options.has_key?(:exclude)
        exclude_opts = if options[:exclude].kind_of?(Array)
          options[:exclude]
        else
          [options[:exclude]]
        end
        exclude_player = exclude_opts.reduce(exclude_player) do |exc, player|
          if player.kind_of?(Player)
            exc || pid == player.id
          else
            exc || pid == player
          end
        end
      end
      next if exclude_player
      if Player.connections[pid]
        Player.connections[pid].each do |conn|
          conn.send_text(message, prompt: false)
        end
      end
    end
  end

  def display_text(player)
    reload
    divider = TextHelpers.full_line("-")
    display = <<-ROOM
\n[f:white:b]#{name}[reset]
#{divider}
[f:green]#{description}[reset]
#{divider}
#{exit_string}
    ROOM
    display += "\n#{player_string(player)}" if players_in_room.where("id <> ?", player.id).online.count > 0
    display
  end

  def exit_array
    exits.keys
  end

  private

  # --- Script Engines -------------------------------------------------------

  def reload_engine
    script_engine.reset
    script_engine.evaluate(self.script || "")
  end

  def script_engine
    reload
    @engine ||= begin
      Room.engines[id] ||= begin
        engine = ES::SharedEngine.new
        engine.evaluate(self.script || "")
        engine
      end
    end
    @engine["@room"] = self
    @engine
  end

  # --- Text Helpers ---------------------------------------------------------

  def player_string(viewing_player)
    players = []
    players_in_room.where("id <> ?", viewing_player.id).online.each do |player|
      players << "[f:green]#{player.display_name} [f:green]is standing here."
    end
    players.join("\n") + "\n"
  end

  def exit_string
    has_exits = exit_array

    str = if has_exits.length == 0
      "NO EXITS."
    else
      has_exits = has_exits.map do |exit_name|
        if exit_open?(exit_name)
          "[f:white:b]#{exit_name}[f:red]"
        else
          "[reset]#{exit_name}[f:red]"
        end
      end
      "EXITS: " + has_exits.join(", ") + "[f:red]."
    end
    "[reset][f:red]#{str}"
  end
end