class CreateSkills < ActiveRecord::Migration
  def change
    create_table :skills do |t|
      t.string :name
      t.string :attribute
      t.string :attr_formula
      t.integer :max_skill_level
      t.integer :exp_per_level

      t.timestamps
    end
  end
end