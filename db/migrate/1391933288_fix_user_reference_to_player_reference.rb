class FixUserReferenceToPlayerReference < ActiveRecord::Migration
  def change
    rename_column :player_trackings, :user_id, :player_id
  end
end
