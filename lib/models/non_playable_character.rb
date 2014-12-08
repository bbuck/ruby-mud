class NonPlayableCharacter < ActiveRecord::Base
  DEFAULT_SCRIPT = <<-SCRIPT.strip_heredoc
    # @me {NonPlayableCharacter} the NPC the script is attached to
    # @room {Room} the room the NPC is currently in

    # Called when a player enters the same room as this NPC.
    # param player {Player} the player who entered the room
    player_entered do |player|
      # respond to the player entering the room
    end

    # Called when a player leaves the room
    # param player {Player} the player who left the room
    player_left do |player|
      # respond to the player leaving the room
    end

    # Called when the player says something in the same room as the NPC. Use
    # this method to make it appear the player is "talking" to this NPC.
    # param player {Player} the player who said something
    # param text {String} the string the player spoke, this is the "X" from the
    #            command "say X"
    player_said do |player, text|
      # respond to the player saying something
    end

    # Called to determine how to display this NPC in the room. By default the
    # idle action is "is standing here" but depending on what the NPC is doing
    # or what kind of NPC this may be somethign like "is hovering here" or "can
    # be seen here
    # return {String} the text to display as the idle action for this NPC.
    idle_action do
      # return an idle action if different from the default, "is standing here"
    end

    # Called when the NPC is told to update, update ticks happen at a minimum
    # of 1 minute intervals, be aware of that.
    update_tick do
      # perform whatever action is necessary to update this NPC, move rooms
      # say something, do something, etc...
    end
  SCRIPT

  extend Memoist

  belongs_to :room
  belongs_to :creator, class_name: "Player"
  has_many :spawned_npcs, class_name: "SpawnedNonPlayableCharacter", foreign_key: :base_npc_id, dependent: :destroy

  before_save :set_default_script
  before_save :reload_script_engines, if: :script_changed?
  before_save :set_spawned_update_times, if: :update_timer_changed?

  scope :name_like, ->(query) { where("name ILIKE ?", "%#{query}%") }

  # --- Helpers --------------------------------------------------------------

  def display_name
    "[f:cyan:b]#{name}"
  end

  def display_description
    unless description.blank?
      "[f:green]#{description}"
    else
      "#{display_name} [f:green]stands before you."
    end
  end

  def spawn(room)
    SpawnedNPC.create(room: room, base_npc: self)
  end

  def eleetscript_allow_methods
    [:spawn]
  end
  memoize :eleetscript_allow_methods

  private

  def set_spawned_update_times
    spawned_npcs.where(next_update: nil).find_each do |npc|
      npc.update_attributes(next_update: Time.now + update_timer.interval_value)
    end
  end

  def reload_script_engines
    spawned_npc_ids.each do |id|
      SpawnedNPC.reload_engine(id, script || "")
    end
  end

  def set_default_script
    if script.blank?
      self.script = DEFAULT_SCRIPT
    end
  end
end

NPC = NonPlayableCharacter