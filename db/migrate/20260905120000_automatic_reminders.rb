class AutomaticReminders < ActiveRecord::Migration[8.1]
  def change
    # O horário do lembrete passa a ser calculado (hora em que o usuário costuma registrar);
    # last_reminded_on garante no máximo um lembrete por dia.
    remove_column :users, :reminder_hour, :integer, null: false, default: 20
    add_column :users, :last_reminded_on, :date
  end
end
