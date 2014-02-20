class ChangeExitsOnRoom < ActiveRecord::Migration
  def change
    remove_column :rooms, :north, :integer
    remove_column :rooms, :south, :integer
    remove_column :rooms, :east, :integer
    remove_column :rooms, :west, :integer
    remove_column :rooms, :northwest, :integer
    remove_column :rooms, :northeast, :integer
    remove_column :rooms, :southwest, :integer
    remove_column :rooms, :southeast, :integer
    remove_column :rooms, :up, :integer
    remove_column :rooms, :down, :integer

    add_column :rooms, :exits, :text
  end
end
