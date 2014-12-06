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

    # Called when the NPC is told to update, update ticks happen at a minimum
    # of 1 minute intervals, be aware of that.
    update_tick do
      # perform whatever action is necessary to update this NPC, move rooms
      # say something, do something, etc...
    end
  SCRIPT

  include Scriptable
  extend Memoist

  belongs_to :room
  belongs_to :creator, class_name: "Player"

  before_save :set_update_at_time
  before_save :set_default_script

  scope :needs_update, -> { where("update_at < ?", Time.now).where.not(room_id: nil) }
  scope :name_like, ->(query) { where("name ILIKE ?", "%#{query}%") }

  script_var_name :me

  class << self
    def update_tick
      Laeron.config.logger.debug("Starting NPC Update Tick.")
      NonPlayableCharacter.needs_update.find_each { |npc| npc.update }
    end
  end

  # --- Helpers --------------------------------------------------------------

  # --- Script Helpers -------------------------------------------------------

  def update_script_variables(engine)
    super
    engine["@room"] = room
  end

  def player_entered(player)
    script_engine.call(:player_entered, player)
  end

  def player_left(player)
    script_engine.call(:player_left, player)
  end

  def player_said(player, text)
    script_engine.call(:player_said, player, text)
  end

  def update
    script_engine.call(:update_tick)
    update_attributes(update_at: Time.now + update_timer.interval_value)
  end

  # --- Script Accessible Helpers --------------------------------------------

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

  def say(msg)
    unless room.nil?
      message = Game::ChannelFormatter.format(:say_to, {"%N" => name, "%M" => msg})
      room.transmit(message)
    end
  end

  def yell(msg)
    unless room.nil?
      message = Game::ChannelFormatter.foramt(:yell, {"%N" => name, "%M" => msg})
      Game::Yell.new(message, room)
    end
  end

  def post(msg)
    unless room.nil?
      message = Game::ChannelFormatter.format(:post, {"%N" => name, "%M" => msg})
      room.transmit(message)
    end
  end

  def xpost(msg)
    unless room.nil?
      message = Game::ChannelFormatter.format(:xpost, {"%M" => msg})
      room.transmit(message)
    end
  end

  def tell(player, msg)
    message = Game::ChannelFormatter.format(:tell_to, {"%N" => name, "%M" => msg})
    player.connection.send_text(message)
  end

  # --- EleetScript Locks ----------------------------------------------------

  def eleetscript_allow_methods
    [:display_name, :say, :tell, :post, :xpost]
  end
  memoize :eleetscript_allow_methods

  private

  def set_default_script
    if script.blank?
      self.script = DEFAULT_SCRIPT
    end
  end

  def set_update_at_time
    if update_timer.present? && update_at.nil?
      self.update_at = Time.now + update_timer.interval_value
    elsif update_timer.nil?
      self.update_at = nil
    end
  end
end

NPC = NonPlayableCharacter