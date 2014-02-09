class CreateRoom < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.string :name
      t.text :description

      # exits
      t.integer :north
      t.integer :south
      t.integer :east
      t.integer :west
      t.integer :northwest
      t.integer :northeast
      t.integer :southwest
      t.integer :southeast
      t.integer :up
      t.integer :down

      t.timestamps
    end
  end
end
