# Callback do login com Google (/auth/google_oauth2/callback).
# Conta nova: cria sem celular e manda para o onboarding (celular -> primeira meta).
# Conta existente com o mesmo e-mail: vincula o Google e entra.
class OmniauthSessionsController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_phone

  def self.configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def create
    auth = request.env["omniauth.auth"]
    user, created = User.from_google(auth)
    start_new_session_for user

    if created || user.phone.blank?
      redirect_to onboarding_phone_path, notice: (t("registrations.flash.created") if created)
    else
      redirect_to after_authentication_url
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_session_path, alert: t("auth.google.failed", reason: e.record.errors.full_messages.to_sentence)
  end

  def failure
    redirect_to new_session_path, alert: t("auth.google.failed", reason: params[:message].to_s.humanize)
  end
end
