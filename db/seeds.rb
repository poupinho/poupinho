# Seeds — Poupinho
#
# Run with: bin/rails db:seed
# Idempotent: safe to run multiple times.

if Rails.env.development?
  email = ENV.fetch("SEED_USER_EMAIL", "demo@economiza.local")
  password = ENV.fetch("SEED_USER_PASSWORD", "trocar-senha-123")

  user = User.find_or_initialize_by(email_address: email)
  user.name = "Usuário Demo"
  user.password = password
  user.password_confirmation = password
  user.phone ||= "11999990000"
  user.monthly_goal ||= 300
  user.admin = true # em dev, o demo também acompanha a área /admin
  user.save!
  puts "Seed: usuário '#{user.email_address}' pronto (senha: #{password})."

  if user.savings.none?
    categories = user.categories.index_by(&:name)
    samples = [
      [ "Almoço", "Levei marmita em vez de comer fora", 18.50 ],
      [ "Transporte", "Fui de bicicleta pro trabalho", 9.80 ],
      [ "Café", "Fiz café em casa", 7.00 ],
      [ "Compras", "Deixei de comprar aquela camiseta", 89.90 ],
      [ "Lazer", "Assisti filme em casa em vez do cinema", 45.00 ],
      [ "Assinaturas", "Cancelei streaming que não usava", 34.90 ],
      [ "Delivery", "Cozinhei em vez de pedir", 52.00 ],
      [ "Outros", "Usei cupom de desconto", 12.30 ]
    ]

    rng = Random.new(42)
    90.times do |i|
      day = Date.current - i
      next if rng.rand < 0.3
      name, description, amount = samples[rng.rand(samples.size)]
      user.savings.create!(
        category: categories[name],
        description: description,
        amount: amount + (rng.rand(5) * 1.25),
        saved_on: day
      )
    end
    puts "Seed: #{user.savings.count} economias de exemplo criadas."
  end

  if user.goals.none?
    [
      { name: "Viagem dos sonhos", icon: "bi-airplane", color: "#0ba360", target_amount: 10_000, deadline: Date.current.end_of_year, position: 0 },
      { name: "Reserva de emergência", icon: "bi-shield-check", color: "#3b82f6", target_amount: 5_000, position: 1 },
      { name: "Celular novo", icon: "bi-phone", color: "#8b5cf6", target_amount: 3_000, position: 2 }
    ].each { |attrs| user.goals.create!(attrs) }

    # Distribui parte das economias entre as metas para o progresso não nascer zerado.
    goals = user.goals.to_a
    user.savings.order(:saved_on).each_with_index do |saving, index|
      saving.update!(goal: goals[index % (goals.size + 1)]) if index % 3 != 2
    end
    puts "Seed: #{user.goals.count} metas de exemplo criadas."
  end
end
