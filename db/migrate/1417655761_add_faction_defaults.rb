class AddFactionDefaults < ActiveRecord::Migration
  def change
    change_column :factions, :friendly_tier, :integer, default: 200
    change_column :factions, :trusted_tier, :integer, default: 800
    change_column :factions, :exalted_tier, :integer, default: 3000
    change_column :factions, :hostility, :integer, default: 3
  end
end
