class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, limit: 60, null: false
      t.string :icon, limit: 60, default: "bi-bullseye", null: false
      t.string :color, limit: 7, default: "#0ba360", null: false
      t.decimal :target_amount, precision: 15, scale: 2, null: false
      t.date :deadline
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :goals, [ :user_id, :name ], unique: true
  end
end
