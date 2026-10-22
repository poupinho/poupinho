class AddAdminToUsers < ActiveRecord::Migration[8.1]
  def change
    # Acesso à área /admin (acompanhamento do sistema). Concedido por `bin/rails admin:grant[email]`.
    add_column :users, :admin, :boolean, null: false, default: false
  end
end
