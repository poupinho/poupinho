class CreateSavings < ActiveRecord::Migration[8.1]
  def change
    create_table :savings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: true, foreign_key: { on_delete: :nullify }
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :description, limit: 255, null: false
      t.date :saved_on, null: false
      t.text :notes

      t.timestamps
    end
    add_index :savings, [ :user_id, :saved_on ]
  end
end
