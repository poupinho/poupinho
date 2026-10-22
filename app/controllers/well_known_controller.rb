# Digital Asset Links: prova ao Android que o app da Play e este domínio são do
# mesmo dono. Sem esse arquivo o app abre com a barra de endereço do Chrome por
# cima do conteúdo, em vez de tela cheia.
#
# O fingerprint só existe depois que o app é assinado, então ele vem do ambiente:
# enquanto não estiver configurado, a rota responde 404 em vez de servir uma
# lista vazia, que o Chrome trataria como verificação falha sem dizer por quê.
class WellKnownController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access

  PACKAGE_NAME = "br.com.poupinho".freeze
  RELATION = "delegate_permission/common.handle_all_urls".freeze

  def assetlinks
    return head :not_found if fingerprints.empty?

    render json: [ {
      relation: [ RELATION ],
      target: {
        namespace: "android_app",
        package_name: PACKAGE_NAME,
        sha256_cert_fingerprints: fingerprints
      }
    } ]
  end

  private

  # SHA-256 dos certificados que assinam o app, em ANDROID_FINGERPRINTS separados
  # por vírgula. São dois na prática: o do Play App Signing, que é quem assina o
  # que chega no celular, e o da chave de upload, para testar o build local.
  def fingerprints
    ENV["ANDROID_FINGERPRINTS"].to_s.split(",").map(&:strip).reject(&:blank?)
  end
end
