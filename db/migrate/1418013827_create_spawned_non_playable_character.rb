class CreateSpawnedNonPlayableCharacter < ActiveRecord::Migration
  def change
    create_table :spawned_non_playable_characters do |t|
      t.belongs_to :base_npc
      t.belongs_to :room
      t.datetime :next_update
      t.datetime :next_respawn
    end
  end
end
