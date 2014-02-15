class AddScriptToRoom < ActiveRecord::Migration
  def change
    add_column :rooms, :script, :text
  end
end
