namespace :admin do
  desc "Concede acesso à área administrativa: bin/rails admin:grant[email]"
  task :grant, [ :email ] => :environment do |_, args|
    user = User.find_by!(email_address: args[:email].to_s.strip.downcase)
    user.update!(admin: true)
    puts "#{user.email_address} agora é admin."
  end

  desc "Revoga acesso à área administrativa: bin/rails admin:revoke[email]"
  task :revoke, [ :email ] => :environment do |_, args|
    user = User.find_by!(email_address: args[:email].to_s.strip.downcase)
    user.update!(admin: false)
    puts "#{user.email_address} não é mais admin."
  end
end
