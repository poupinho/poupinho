module Admin
  # Área de acompanhamento do sistema, somente leitura, restrita a usuários com `admin: true`.
  class BaseController < ApplicationController
    before_action :require_admin
    layout "application"

    private

    def require_admin
      return if current_user&.admin?

      redirect_to dashboard_path, alert: t("admin.flash.forbidden")
    end
  end
end
