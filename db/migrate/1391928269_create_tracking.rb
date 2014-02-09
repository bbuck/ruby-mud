class CreateTracking < ActiveRecord::Migration
  def change
    create_table :player_trackings do |t|
      t.string :ip_address
      t.integer :connection_count
      t.references :user

      t.timestamps
    end

    add_index :player_trackings, :ip_address
  end
end
