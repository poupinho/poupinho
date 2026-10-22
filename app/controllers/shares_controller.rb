# Destino do QR code do card compartilhável. É um endereço curto de propósito:
# quanto menor a URL, menos módulos o QR tem e mais fácil ele é de ler numa foto
# de story. O redirecionamento acrescenta a marcação de origem, para o analytics
# separar quem chegou pelo card de quem chegou pela busca.
class SharesController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access

  CAMPAIGN = { utm_source: "share_card", utm_medium: "qrcode", utm_campaign: "poupinho" }.freeze

  def qr
    redirect_to root_path(CAMPAIGN), allow_other_host: false
  end
end
