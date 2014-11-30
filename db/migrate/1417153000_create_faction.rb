class CreateFaction < ActiveRecord::Migration
  def change
    create_table :factions do |t|
      t.string :name
      t.integer :hostility
      t.integer :friendly_tier
      t.integer :trusted_tier
      t.integer :exalted_tier
    end
  end
end
