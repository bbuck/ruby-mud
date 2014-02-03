class CreatePlayer < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :username
      t.string :password_hash

      t.timestamps
    end
  end
end
