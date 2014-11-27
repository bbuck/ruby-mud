class AddPromptToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :prompt, :string
  end
end