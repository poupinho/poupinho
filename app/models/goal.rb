class Goal < ApplicationRecord
  COLOR_FORMAT = /\A#\h{6}\z/

  belongs_to :user
  has_many :savings, dependent: :nullify

  normalizes :name, with: ->(n) { n.to_s.strip.squeeze(" ") }
  normalizes :icon, with: ->(i) { i.to_s.strip.presence || "bi-bullseye" }
  normalizes :color, with: ->(c) { c.to_s.strip.downcase }

  validates :name, presence: true, length: { maximum: 60 },
                   uniqueness: { scope: :user_id, case_sensitive: false }
  validates :icon, presence: true, length: { maximum: 60 },
                   format: { with: /\Abi-[a-z0-9-]+\z/, message: "deve ser um ícone do Bootstrap Icons (ex.: bi-bullseye)" }
  validates :color, presence: true, format: { with: COLOR_FORMAT, message: "deve estar no formato #RRGGBB" }
  validates :target_amount, presence: true, numericality: { greater_than: 0, less_than: 1_000_000_000 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :created_at) }
end
