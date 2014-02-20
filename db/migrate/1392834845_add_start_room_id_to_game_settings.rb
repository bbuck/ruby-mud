class AddStartRoomIdToGameSettings < ActiveRecord::Migration
  def change
    add_column :game_settings, :initial_room_id, :integer, default: 1
  end
end
