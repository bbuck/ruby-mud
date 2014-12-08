class SpawnedNonPlayableCharacter < ActiveRecord::Base
  include Scriptable
  extend Memoist

  belongs_to :room
  belongs_to :base_npc, class_name: "NonPlayableCharacter"

  before_save :set_update_at_time

  validates :base_npc_id, presence: true

  scope :needs_update, -> { in_room.where("next_update < ?", Time.now) }
  scope :needs_respawn, -> { where("next_respawn < ?", Time.now) }
  scope :with_base_npc, ->(base_npc) { where(base_npc_id: base_npc.id) }
  scope :in_room, -> { where.not(room_id: nil) }
  scope :not_in_room, -> { where(room_id: nil) }

  script_var_name :me

  delegate :script, :update_timer, :respawn_timer, :display_name, :display_description, :script_changed?, :name, to: :base_npc

  class << self
    def update_tick
      Laeron.config.logger.debug("Starting NPC update tick")
      SpawnedNPC.needs_update.find_each do |npc|
        EM.next_tick { npc.update }
      end
      Laeron.config.logger.debug("Completed NPC update tick")
    end

    def purge_obselete
      Laeron.config.logger.debug("Starting NPC purge")
      SpawnedNPC.not_in_room.destroy_all
      # TODO: Destroy dead NPCs as well
      Laeron.config.logger.debug("Completed NPC purge")
    end
  end

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
    update_attributes(next_update: Time.now + update_timer.interval_value)
  end

  def idle_action
    idle_action = script_engine.call(:idle_action)
    if idle_action.blank?
      "[f:green]is standing here."
    else
      "[f:green]#{idle_action}"
    end
  end

  # --- Script Accessible Helpers ---------------------------------------------

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
    player.write(message)
  end

  def npc_id
    base_npc.id
  end

  def spawn_npc(id, room_id)
    begin
      NPC.find(id).spawn(Room.find(room_id))
    rescue ActiveRecord::RecordNotFound => e
      nil
    end
  end

  # --- EleetScript Locks ----------------------------------------------------

  def eleetscript_allow_methods
    [:display_name, :say, :tell, :post, :xpost, :npc_id, :spawn_npc]
  end
  memoize :eleetscript_allow_methods

  private

  def set_update_at_time
    if update_timer.present? && next_update.nil?
      self.next_update = Time.now + update_timer.interval_value
    elsif update_timer.nil?
      self.next_update = nil
    end
  end
end

SpawnedNPC = SpawnedNonPlayableCharacter