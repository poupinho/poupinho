class SessionsController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Muitas tentativas. Tente novamente em alguns minutos." }

  def new
    redirect_to dashboard_path if authenticated?
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "E-mail ou senha incorretos. Verifique seus dados e tente novamente."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
