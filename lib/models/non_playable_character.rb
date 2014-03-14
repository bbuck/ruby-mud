class NonPlayableCharacter < ActiveRecord::Base
  include Scriptable

  belongs_to :room
  belongs_to :creator, class_name: "Player"

  script_var_name :me

  # --- Script Responders ----------------------------------------------------

  def player_said(player, text)
    script_engine.call(:player_said, player, text)
  end

  # --- Text Helpers ---------------------------------------------------------

  def display_name
    "[f:cyan:b]#{name}"
  end

  # --- EleetScript Locks ----------------------------------------------------

  def eleetscript_allow_metods
    [:display_name]
  end
end