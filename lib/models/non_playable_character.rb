class NonPlayableCharacter < ActiveRecord::Base
  include Scriptable

  belongs_to :room
  belongs_to :creator, class_name: "Player"

  script_var_name :me

  # --- Script Helpers -------------------------------------------------------

  def update_script_variables(engine)
    super
    unless room.nil?
      engine["@room"] = room
    end
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
  end

  # --- Script Accessible Helpers --------------------------------------------

  def display_name
    "[f:cyan:b]#{name}"
  end

  def say(msg)
    unless room.nil?
      message = ChannelFormatter.format(:say_to, {"%N" => name, "%M" => msg})
      room.transmit(msg)
    end
  end

  def post(msg)

  end

  def whisper(player, msg)

  end

  # --- EleetScript Locks ----------------------------------------------------

  def eleetscript_allow_metods
    [:display_name, :say, :whisper, :post]
  end
end