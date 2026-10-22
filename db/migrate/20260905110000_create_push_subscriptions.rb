class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    # Assinaturas Web Push (uma por navegador/dispositivo) para os lembretes.
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false, limit: 1000
      t.string :p256dh, null: false
      t.string :auth, null: false
      t.string :user_agent, limit: 255
      t.timestamps
    end
    add_index :push_subscriptions, :endpoint, unique: true

    # Hora do dia (0..23, fuso de Brasília) em que o lembrete é enviado se ainda não houve economia.
    add_column :users, :reminder_hour, :integer, null: false, default: 20
  end
end
