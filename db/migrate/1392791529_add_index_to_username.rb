class AddIndexToUsername < ActiveRecord::Migration
  def change
    add_index :players, :username
  end
end
