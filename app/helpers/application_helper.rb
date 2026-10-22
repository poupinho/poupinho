module ApplicationHelper
  # R$ 1.234,56
  def format_brl(value, precision: 2)
    number_to_currency(value.to_d, unit: "R$", separator: ",", delimiter: ".", precision: precision, format: "%u %n")
  end

  # Valor decimal formatado para o campo com máscara de moeda (1234.5 -> "1.234,50").
  def brl_input_value(value)
    return "" if value.blank?
    number_with_precision(value.to_d, precision: 2, separator: ",", delimiter: ".")
  end

  # "Setembro/2026"
  def month_name(date)
    "#{l(date, format: '%B')}/#{date.year}"
  end

  # "Hoje", "Ontem" ou a data por extenso curta (DD/MM/AAAA).
  def relative_date(date)
    case date
    when Date.current then t("dates.today")
    when Date.yesterday then t("dates.yesterday")
    else l(date)
    end
  end

  # ID de medição do Google Analytics 4 ("G-XXXXXXXXXX"); vazio desliga o analytics.
  def analytics_id
    ENV["GA_MEASUREMENT_ID"].to_s.strip.presence
  end

  def page_title(title)
    content_for(:title, "#{title} — #{t('app.name')}")
  end

  # Descrição para as meta tags (SEO / compartilhamento) da página atual.
  def page_description(text)
    content_for(:description, text)
  end

  # Endereço público do site. Em produção vem do APP_HOST, para que o sitemap e
  # o <link rel="canonical"> apontem sempre para o mesmo domínio, mesmo quando a
  # visita chegou pelo www.
  def canonical_base_url
    host = ENV["APP_HOST"].to_s.strip
    host.present? ? "https://#{host}" : request.base_url
  end

  def canonical_url(path = request.path)
    "#{canonical_base_url}#{path}"
  end

  # Iniciais do usuário para o avatar ("Rafael Mateus" -> "RM").
  def user_initials(user)
    parts = user.display_name.split(/[\s@._-]+/).reject(&:blank?)
    parts.first(2).map { |p| p[0] }.join.upcase.presence || "?"
  end

  # Avatar redondo: a foto (variante 160x160) quando existe, senão as iniciais.
  def user_avatar(user, css_class: nil, **attrs)
    classes = [ "ec-avatar", css_class ].compact.join(" ")
    if user.avatar.attached? && user.avatar.variable?
      tag.span(class: classes, **attrs) { image_tag polymorphic_path(user.avatar.variant(:thumb)), alt: user.display_name, loading: "lazy" }
    else
      tag.span(user_initials(user), class: classes, **attrs)
    end
  end

  # Itens da navegação principal (topo no desktop, barra inferior no mobile).
  def main_nav_items
    [
      { label: t("nav.dashboard"),  path: dashboard_path,  icon: "bi-house",       icon_active: "bi-house-fill",
        active: controller_name == "dashboard" },
      { label: t("nav.savings"),    path: savings_path,    icon: "bi-clock-history", icon_active: "bi-clock-history",
        active: controller_name == "savings" && !%w[new create].include?(action_name) },
      { label: t("nav.goals"),      path: goals_path,      icon: "bi-bullseye",    icon_active: "bi-bullseye",
        active: controller_name == "goals" },
      { label: t("nav.reports"),    path: reports_path,    icon: "bi-bar-chart",   icon_active: "bi-bar-chart-fill",
        active: controller_name == "reports" }
    ]
  end

  # Categorias fica só na nav do desktop; no mobile vive no menu do usuário.
  def categories_nav_item
    { label: t("nav.categories"), path: categories_path, icon: "bi-tags", icon_active: "bi-tags-fill",
      active: controller_name == "categories" }
  end

  def nav_link(item)
    icon = item[:active] ? item[:icon_active] : item[:icon]
    link_to item[:path], class: "nav-link #{'active' if item[:active]}",
                         aria: ({ current: "page" } if item[:active]) do
      safe_join([ content_tag(:i, nil, class: "bi #{icon}"), content_tag(:span, item[:label]) ])
    end
  end

  def category_badge(category, size: nil)
    return content_tag(:span, t("savings.form.no_category"), class: "ec-category-badge ec-category-badge-none") if category.nil?

    content_tag(:span, class: "ec-category-badge #{size}", style: "--cat-color: #{category.color}") do
      safe_join([ content_tag(:i, nil, class: "bi #{category.icon}"), " ", category.name ])
    end
  end

  def category_icon(category, css: "")
    color = category&.color || "#6b7280"
    icon = category&.icon || "bi-tag"
    content_tag(:span, class: "ec-category-icon #{css}", style: "--cat-color: #{color}") do
      content_tag(:i, nil, class: "bi #{icon}")
    end
  end
end
