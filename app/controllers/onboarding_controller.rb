# Passos obrigatórios depois do login com Google: celular (aqui) e depois a primeira meta
# (GoalsController#new com onboarding=1). ApplicationController#require_phone traz de volta
# quem ainda não tem celular.
class OnboardingController < ApplicationController
  skip_before_action :require_phone

  def phone
    redirect_to new_goal_path(onboarding: 1) if current_user.phone.present?
  end

  def save_phone
    if current_user.update(phone: params.dig(:user, :phone))
      redirect_to new_goal_path(onboarding: 1)
    else
      render :phone, status: :unprocessable_content
    end
  end
end
