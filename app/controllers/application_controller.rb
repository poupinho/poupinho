class ApplicationController < ActionController::Base
  include Authentication
  before_action :require_phone

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def current_user
    Current.user
  end
  helper_method :current_user

  # Conta sem celular (criada pelo Google) só segue depois de informar o número.
  def require_phone
    return unless authenticated? && current_user.phone.blank?

    redirect_to onboarding_phone_path
  end
end
