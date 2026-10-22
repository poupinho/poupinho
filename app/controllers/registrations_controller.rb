class RegistrationsController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Muitas tentativas. Tente novamente em alguns minutos." }

  def new
    redirect_to dashboard_path and return if authenticated?
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      # Onboarding: a primeira parada é criar uma meta, para cada economia já ter um destino.
      redirect_to new_goal_path(onboarding: 1), notice: t("registrations.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(:name, :email_address, :phone, :password, :password_confirmation)
  end
end
