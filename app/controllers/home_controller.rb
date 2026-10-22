class HomeController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access

  # Raiz pública para todo mundo: quem está logado vê a landing com atalhos para o app.
  def index
    load_examples
    render :landing
  end

  private

  def load_examples
    @examples = Simulations::Projection::EXAMPLE_DAILY_AMOUNTS.map do |daily|
      Simulations::Projection.call(daily: daily)
    end
  end
end
