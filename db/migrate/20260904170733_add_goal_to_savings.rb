class AddGoalToSavings < ActiveRecord::Migration[8.1]
  def change
    add_reference :savings, :goal, null: true, foreign_key: { on_delete: :nullify }
  end
end
