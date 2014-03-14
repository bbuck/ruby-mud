class CreateNonPlayableCharacters < ActiveRecord::Migration
  def change
    create_table :non_playable_characters do |t|
      t.integer :creator_id, null: false
      t.references :room

      t.string :name, null: false
      t.text :script
      t.string :update_timer
      t.datetime :update_at
      t.string :respawn_timer
      t.datetime :respawn_at

      t.timestamps
    end
  end
end
