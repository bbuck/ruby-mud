class AddDescriptionToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :description, :text
  end
end
