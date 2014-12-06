class AddDescriptionToNpc < ActiveRecord::Migration
  def change
    add_column :non_playable_characters, :description, :text
  end
end
