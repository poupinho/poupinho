# Páginas públicas de Política de Privacidade e Termos de Uso (exigidas pelo login com Google).
class LegalController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access

  def privacy
  end

  def terms
  end

  def account_deletion
  end
end
