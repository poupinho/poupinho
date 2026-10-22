# Assinaturas Web Push do navegador atual (JSON, chamado pelo controller Stimulus `push`).
class PushSubscriptionsController < ApplicationController
  def create
    subscription = PushSubscription.find_or_initialize_by(endpoint: subscription_params[:endpoint])
    subscription.assign_attributes(
      user: current_user,
      p256dh: subscription_params.dig(:keys, :p256dh),
      auth: subscription_params.dig(:keys, :auth),
      user_agent: request.user_agent&.first(255)
    )

    if subscription.save
      head :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    current_user.push_subscriptions.where(endpoint: params[:endpoint]).destroy_all
    head :no_content
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, keys: [ :p256dh, :auth ])
  end
end
