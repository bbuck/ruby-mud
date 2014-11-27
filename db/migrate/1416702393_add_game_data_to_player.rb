class AddGameDataToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :game_data, :text
  end
end
