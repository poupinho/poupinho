# Sitemap gerado a partir das rotas públicas, para que cada dica nova entre no
# índice sem ninguém precisar lembrar de editar um XML na mão.
class SitemapController < ApplicationController
  skip_before_action :require_phone
  allow_unauthenticated_access

  # As páginas fixas: a landing primeiro, depois cadastro, login e as legais.
  STATIC_PAGES = [
    { path: "/",                  changefreq: "weekly",  priority: "1.0" },
    { path: "/registration/new",  changefreq: "monthly", priority: "0.8" },
    { path: "/session/new",       changefreq: "monthly", priority: "0.5" },
    { path: "/privacidade",       changefreq: "yearly",  priority: "0.3" },
    { path: "/termos",            changefreq: "yearly",  priority: "0.3" },
    { path: "/excluir-conta",     changefreq: "yearly",  priority: "0.3" }
  ].freeze

  def show
    @entries = STATIC_PAGES + tip_pages
    render formats: :xml
  end

  private

  def tip_pages
    [ { path: tips_path, changefreq: "monthly", priority: "0.7" } ] +
      Tip.all.map { |tip| { path: tip_path(tip), changefreq: "monthly", priority: "0.6" } }
  end
end
