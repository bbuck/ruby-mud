class AddPermissionToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :permissions, :integer, default: 0
  end
end
