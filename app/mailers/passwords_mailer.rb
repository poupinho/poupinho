class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Redefinição de senha — Poupinho", to: user.email_address
  end
end
