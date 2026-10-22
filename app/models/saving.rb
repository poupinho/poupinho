class Saving < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :goal, optional: true

  normalizes :description, with: ->(d) { d.to_s.strip.squeeze(" ").presence }

  validates :amount, presence: true, numericality: { greater_than: 0, less_than: 1_000_000_000 }
  validates :description, length: { maximum: 255 }
  validates :saved_on, presence: true
  validate :category_belongs_to_user
  validate :goal_belongs_to_user
  validate :saved_on_not_in_future

  scope :recent, -> { order(saved_on: :desc, created_at: :desc) }
  scope :on_month, ->(date) { where(saved_on: date.beginning_of_month..date.end_of_month) }
  scope :on_year, ->(year) { where(saved_on: Date.new(year, 1, 1)..Date.new(year, 12, 31)) }
  scope :search, ->(term) {
    term = term.to_s.strip
    term.present? ? where("savings.description ILIKE ?", "%#{sanitize_sql_like(term)}%") : all
  }

  # Texto exibido nas listas: descrição, senão o nome da categoria, senão um genérico.
  def title
    description.presence || category&.name || I18n.t("savings.untitled")
  end

  private

  def category_belongs_to_user
    return if category.nil? || user.nil?
    errors.add(:category, :invalid) if category.user_id != user_id
  end

  def goal_belongs_to_user
    return if goal.nil? || user.nil?
    errors.add(:goal, :invalid) if goal.user_id != user_id
  end

  def saved_on_not_in_future
    return if saved_on.blank?
    errors.add(:saved_on, "não pode ser no futuro") if saved_on > Date.current
  end
end
