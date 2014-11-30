class CreateReputation < ActiveRecord::Migration
  def change
    create_table :reputations do |t|
      t.belongs_to :faction
      t.integer :value
    end
  end
end
