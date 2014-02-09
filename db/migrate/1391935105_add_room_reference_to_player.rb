class AddRoomReferenceToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :room_id, :integer
  end
end
