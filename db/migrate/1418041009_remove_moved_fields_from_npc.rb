class RemoveMovedFieldsFromNpc < ActiveRecord::Migration
  def change
    remove_column :non_playable_characters, :room_id, :integer
    remove_column :non_playable_characters, :respawn_at, :datetime
    remove_column :non_playable_characters, :update_at, :datetime
  end
end
