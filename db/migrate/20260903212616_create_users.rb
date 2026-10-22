class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, limit: 120
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.decimal :monthly_goal, precision: 15, scale: 2

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
