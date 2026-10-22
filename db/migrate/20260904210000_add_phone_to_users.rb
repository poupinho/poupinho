class AddPhoneToUsers < ActiveRecord::Migration[8.1]
  def change
    # Só dígitos (DDD + 9 dígitos). Nulo para contas anteriores à obrigatoriedade no cadastro.
    add_column :users, :phone, :string, limit: 11
  end
end
