class CreatePlayersReputations < ActiveRecord::Migration
  def change
    create_table :players_reputations do |t|
      t.belongs_to :player
      t.belongs_to :reputation
    end

    add_index :players_reputations, :player_id
    add_index :players_reputations, [:player_id, :reputation_id]
  end
end
