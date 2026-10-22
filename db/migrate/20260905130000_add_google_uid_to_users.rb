class AddGoogleUidToUsers < ActiveRecord::Migration[8.1]
  def change
    # Conta Google vinculada (login com Google). Nulo para quem entra só com senha.
    add_column :users, :google_uid, :string
    add_index :users, :google_uid, unique: true
  end
end
