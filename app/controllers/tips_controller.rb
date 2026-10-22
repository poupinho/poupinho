# Dicas para poupar. Páginas públicas: são a porta de entrada de quem chega
# pela busca, então não exigem login e são indexáveis.
class TipsController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access

  def index
    @groups = Tip.groups
  end

  def show
    @tip = Tip.find!(params[:slug])
  end
end
