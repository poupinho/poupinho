# Dicas para poupar. O conteúdo é estático e vive no locale (chave tips.groups);
# esta classe dá a ele slugs estáveis, para as páginas públicas de /dicas, e os
# acessos que as views, o sitemap e os links entre dicas precisam.
#
# Não é um registro do banco: nada aqui é criado ou editado em runtime.
class Tip
  Group = Struct.new(:slug, :title, :icon, :color, :tips, keyword_init: true)

  ATTRIBUTES = %i[ slug title text icon saving description body steps math ].freeze

  attr_reader(*ATTRIBUTES)
  attr_reader :group

  class << self
    def groups
      cache[I18n.locale] ||= build_groups
    end

    def all
      groups.flat_map(&:tips)
    end

    def find(slug)
      all.find { |tip| tip.slug == slug.to_s }
    end

    # Usado pelo controller: slug desconhecido vira 404, como um registro ausente.
    def find!(slug)
      find(slug) || raise(ActiveRecord::RecordNotFound, "dica não encontrada: #{slug}")
    end

    # Só para os testes: o conteúdo não muda em runtime, então o cache é permanente.
    def reload!
      @cache = nil
    end

    private

    def cache
      @cache ||= {}
    end

    def build_groups
      I18n.t("tips.groups").map do |attrs|
        group = Group.new(**attrs.slice(:slug, :title, :icon, :color), tips: [])
        group.tips.concat(attrs[:items].map { |item| new(item, group) })
        group.tips.freeze
        group.freeze
      end.freeze
    end
  end

  def initialize(attrs, group)
    ATTRIBUTES.each { |name| instance_variable_set(:"@#{name}", attrs[name]) }
    @body = Array(@body).freeze
    @steps = Array(@steps).freeze
    @group = group
    freeze
  end

  # As demais dicas do mesmo grupo, para os links no fim da página.
  def related
    group.tips.reject { |tip| tip.slug == slug }
  end

  def to_param
    slug
  end
end
