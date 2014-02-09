class CreateGameSettings < ActiveRecord::Migration
  def change
    create_table :game_settings do |t|
      t.string :content_title, default: ""
      t.text :game_title, default: ""

      t.timestamps
    end
  end
end
