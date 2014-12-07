class Room < ActiveRecord::Base
  DEFAULT_SCRIPT = <<-SCRIPT.strip_heredoc
    # @room {Room} the room this script is attached to

    # Called when the player signs in and "appears" in the room they were last
    # in.
    # param player {Player} the player who appeared (just signed in)
    player_appears do |player|
      # Do something when the player appears
    end

    # Called when the player enters the room from another room vai the given
    # direction.
    # param player {Player} the player who entered the room
    # param direction {Symbol} the direction the player entered from
    player_entered do |player, direction|
      # do something when the player enters the room
    end

    # Called when the player leaves the room and is given the direction they
    # left by
    # param player {Player} the player who left
    # param direction {Symbol} the direction the player left
    player_left do |player, direction|
      # do something when the player leaves the room
    end

    # Called when the player types "look X" where X is not an object, player or
    # NPC in the room
    # param player {Player} the player who did the looking
    # param object {String} the "X" from "look X"
    # return {String} the return value should be a string if the text is
    #        something the player should see, nothing if the player doesn't
    #        see anything
    player_looks_at do |player, object|
      # test object and return appropraite string or nothing if the player
      # doesn't see anything
    end
  SCRIPT

  include Scriptable
  extend Memoist

  Helpers::Exit.each do |exit_name|
    define_method exit_name do
      reload
      if exits.has_key?(exit_name)
        Room.find(exits[exit_name][:destination])
      else
        nil
      end
    end
  end

  serialize :exits, Hash

  has_many :players_in_room, class_name: "Player"
  has_many :npcs_in_room, class_name: "NonPlayableCharacter"
  belongs_to :creator, class_name: "Player"

  scope :name_like, ->(name) { where("name ILIKE ?", "%#{name}%") }

  before_save :set_default_script

  script_var_name :room

  # --- Player Actions -------------------------------------------------------

  def player_appears(player)
    transmit("[f:green]#{player.display_name} appears magically.")
    script_engine.call(:player_appears, player)
  end

  def player_enters(player, dir)
    from_dir = Helpers::Exit.proper(Helpers::Exit.inverse(dir))
    transmit("[f:green]#{player.display_name} [f:green]enters from #{from_dir}.")
    player.write(display_text(player), newline: false)
    script_engine.call(:player_entered, player, Helpers::Exit.inverse(dir))
    npcs_in_room.each { |npc| npc.player_entered(player) }
  end

  def player_left(player, dir)
    from_dir = Helpers::Exit.proper(dir)
    text = "[f:green]#{player.display_name} [f:green]"
    if from_dir == "above"
      text += "leaves up."
    elsif from_dir == "below"
      text += "leaves #{from_dir}."
    else
      text += "leaves to #{from_dir}."
    end
    transmit(text)
    script_engine.call(:player_left, player, dir)
    npcs_in_room.each { |npc| npc.player_left(player) }
  end

  def player_looks_at(player, object)
    if object == "me" || object == "self"
      Helpers::Text.string("[f:green]You look at yourself", player.display_description)
    elsif players_in_room.with_username(object).count > 0
      other_player = players_in_room.with_username(object).first
      Helpers::Text.string("[f:green]You look at #{other_player.display_name}", other_player.display_description)
    elsif npcs_in_room.name_like(object).count > 0
      npc = npcs_in_room.name_like(object).first
      Helpers::Text.string("[f:green]You look at #{npc.display_name}", npc.display_description)
    else
      script_engine.call(:player_looks_at, player, object)
    end
  end

  # --- Overrides ------------------------------------------------------------

  def update_attributes(map)
    super
    reload_engine if map.has_key?(:script)
  end

  def update_attribute(prop, val)
    super
    reload_engine if prop == :script
  end

  # --- Exit Management ------------------------------------------------------

  def remove_exit(dir, options = {})
    if has_exit?(dir)
      if options[:unlink_other]
        other_room = send(dir)
        other_room.remove_exit(Helpers::Exit.inverse(dir))
      end
      exits.delete(dir)
      save
    end
  end

  def add_exit(dir, destination, options = {})
    if Helpers::Exit.valid?(dir)
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
        other_room.add_exit(Helpers::Exit.inverse(dir), self.id)
      end
    end
  end

  # --- Open/Closing Helpers -------------------------------------------------

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
    send(dir).open_exit(Helpers::Exit.inverse(dir), false) if open_opposite
    :success
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
    send(dir).close_exit(Helpers::Exit.inverse(dir), false)
    :success
  end

  def exit_open?(dir)
    exit_status(dir) == :open
  end

  # --- Lock/Unlocking Helpers -----------------------------------------------

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
    send(dir).unlock_exit(Helpers::Exit.inverse(dir), nil, false) if unlock_opposite
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
    send(dir).lock_exit(Helpers::Exit.inverse(dir), false) if lock_opposite
    :success
  end

  # --- Exit Management Helpers ----------------------------------------------

  def add_door_to(direction, timer, options = {})
    if has_exit?(direction)
      exits[direction.to_sym][:door] = { open: false, timer: timer, close_at: nil }
      save
      if options[:add_to_link]
        send(direction).add_door_to(Helpers::Exit.inverse(direction), timer)
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
        send(direction).add_lock_to(Helpers::Exit.inverse(direction), timer)
      end
    end
  end

  def remove_lock_from(direction, options = {})
    if has_exit?(direction)
      exits[direction.to_sym].delete(:lock)
      save
      if options[:remove_from_link]
        send(direction).remove_lock_from(Helpers::Exit.inverse(direction))
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
        send(direction).remove_door_from(Helpers::Exit.inverse(direction))
      end
    end
  end

  # --- General Exit Helpers -------------------------------------------------

  def exit_array
    exits.keys
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

  def has_exit?(dir)
    exits.has_key?(dir)
  end

  # --- Helpers --------------------------------------------------------------

  def player_transmit(txt, player, message, opts = {})
    transmit(txt, opts)
    npcs_in_room.each { |npc| npc.player_said(player, message) }
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
      if Player.tcp_connections[pid]
        Player.tcp_connections[pid].each do |conn|
          conn.write(message, prompt: false)
        end
      end
    end
  end

  def display_name
    "[f:white:b]#{name}"
  end

  def display_text(player)
    reload
    divider = Helpers::Text.full_line("-")
    display = [
      "",
      "#{display_name}[reset]",
      divider,
      "[f:green]#{description}[reset]",
      divider,
      exit_string,
      ""
    ].join("\n")
    display + "#{contents_string(player)}"
  end

  private

  # --- Text Helpers ---------------------------------------------------------

  def contents_string(viewing_player)
    contents = []
    contents += npc_string_data if npcs_in_room.count > 0
    contents += player_string_data(viewing_player) if players_in_room.where.not(id: viewing_player.id).online.count > 0
    if contents.length > 0
      "\n" + contents.join("\n") + "\n"
    else
      ""
    end
  end

  def npc_string_data(padding = "")
    npcs = []
    npcs_in_room.each do |npc|
      npcs << "#{padding}[f:green]#{npc.display_name} [reset]#{npc.idle_action}"
    end
    npcs
  end

  def player_string_data(viewing_player, padding = "")
    players = []
    players_in_room.where("id <> ?", viewing_player.id).online.each do |player|
      players << "#{padding}[f:green]#{player.display_name} [f:green]is standing here."
    end
    players
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

  def eleetscript_allow_methods
    [:display_name, :transmit]
  end
  memoize :eleetscript_allow_methods

  private

  def set_default_script
    if script.blank?
      self.script = DEFAULT_SCRIPT
    end
  end
end