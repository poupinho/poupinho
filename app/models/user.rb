class User < ApplicationRecord
  DEFAULT_CATEGORIES = [
    { name: "Almoço",      icon: "bi-egg-fried",   color: "#f59e0b" },
    { name: "Café",        icon: "bi-cup-hot",     color: "#92400e" },
    { name: "Transporte",  icon: "bi-bus-front",   color: "#3b82f6" },
    { name: "Delivery",    icon: "bi-bag-check",   color: "#ef4444" },
    { name: "Compras",     icon: "bi-cart3",       color: "#8b5cf6" },
    { name: "Lazer",       icon: "bi-controller",  color: "#ec4899" },
    { name: "Assinaturas", icon: "bi-tv",          color: "#06b6d4" },
    { name: "Outros",      icon: "bi-tag",         color: "#6b7280" }
  ].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :categories, -> { order(:position, :name) }, dependent: :destroy
  has_many :savings, dependent: :destroy
  has_many :goals, -> { ordered }, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  # Foto de perfil (upload no perfil ou baixada do Google no primeiro login).
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 160, 160 ], saver: { quality: 85 }
  end

  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  AVATAR_MAX_BYTES = 5.megabytes

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.to_s.strip }
  normalizes :phone, with: ->(p) { p.to_s.gsub(/\D/, "").presence }

  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, length: { maximum: 120 }, allow_blank: true
  # Obrigatório no cadastro (o login com Google pede no onboarding); contas antigas podem ainda não ter.
  # Formato: DDD + celular (9 dígitos).
  attr_accessor :from_google
  attr_accessor :remove_avatar # checkbox do perfil; o purge acontece no ProfilesController
  validates :phone, presence: true, on: :create, unless: :from_google
  validates :phone, format: { with: /\A[1-9]{2}9\d{8}\z/, message: "deve ser um celular válido com DDD, ex.: (11) 91234-5678" }, allow_nil: true
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :monthly_goal, numericality: { greater_than: 0 }, allow_nil: true
  validate :avatar_is_a_small_image

  after_create :create_default_categories

  # Login com Google: encontra pelo uid, senão vincula pelo e-mail, senão cria.
  # Ao criar ou vincular, a foto do Google é baixada em background (GoogleAvatarJob).
  # Retorna [user, criado?].
  def self.from_google(auth)
    info = auth.info
    if (user = find_by(google_uid: auth.uid))
      return [ user, false ]
    end

    email = info.email.to_s.strip.downcase
    if (user = find_by(email_address: email))
      user.update!(google_uid: auth.uid)
      user.fetch_google_avatar(info.image)
      return [ user, false ]
    end

    user = new(email_address: email, name: info.name.to_s.first(120), google_uid: auth.uid, from_google: true)
    password = SecureRandom.base58(32)
    user.password = password
    user.password_confirmation = password
    user.save!
    user.fetch_google_avatar(info.image)
    [ user, true ]
  end

  # Agenda o download da foto do Google, sem sobrescrever uma foto que o usuário já tenha.
  def fetch_google_avatar(url)
    return if url.blank? || avatar.attached?
    GoogleAvatarJob.perform_later(self, url)
  end

  # Busca por nome ou e-mail (área admin).
  scope :search, ->(term) {
    term = term.to_s.strip
    term.present? ? where("users.name ILIKE :q OR users.email_address ILIKE :q", q: "%#{sanitize_sql_like(term)}%") : all
  }

  # Agrega contagem, total e última data das economias sem N+1 (área admin).
  scope :with_savings_stats, -> {
    left_joins(:savings)
      .select("users.*, COUNT(savings.id) AS savings_count, COALESCE(SUM(savings.amount), 0) AS savings_total, MAX(savings.saved_on) AS last_saved_on")
      .group("users.id")
  }

  def display_name
    name.presence || email_address
  end

  def first_name
    display_name.split(/[\s@]/).first
  end

  # "(11) 91234-5678"
  def formatted_phone
    return if phone.blank?
    "(#{phone[0, 2]}) #{phone[2, 5]}-#{phone[7, 4]}"
  end

  private

  def avatar_is_a_small_image
    return unless avatar.attached?
    errors.add(:avatar, :invalid_type) unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
    errors.add(:avatar, :too_large) if avatar.byte_size > AVATAR_MAX_BYTES
  end

  def create_default_categories
    DEFAULT_CATEGORIES.each_with_index do |attrs, index|
      categories.create!(attrs.merge(position: index))
    end
  end
end
