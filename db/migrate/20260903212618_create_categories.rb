class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, limit: 60, null: false
      t.string :icon, limit: 60, null: false, default: "bi-tag"
      t.string :color, limit: 7, null: false, default: "#10b981"
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :categories, [ :user_id, :name ], unique: true
  end
end
