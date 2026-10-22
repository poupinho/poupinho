module Admin
  # Números do sistema inteiro para a área administrativa (somente leitura).
  # Séries dos últimos 30 dias por dia; valores monetários em BigDecimal.
  class Overview
    DAYS = 30

    Result = Struct.new(
      :users_total, :users_7d, :users_30d, :active_users_7d, :active_users_30d, :admins_total,
      :savings_count, :savings_total, :savings_today_count, :savings_today_total, :savings_7d_total,
      :goals_count, :goals_achieved_count, :categories_count, :push_users, :push_devices,
      :signups_by_day, :savings_by_day, :top_categories, :latest_users, :latest_savings,
      keyword_init: true
    )

    def self.call(as_of: Date.current)
      new(as_of: as_of).call
    end

    def initialize(as_of:)
      @as_of = as_of
    end

    def call
      Result.new(
        users_total: User.count,
        users_7d: User.where(created_at: (as_of - 6).beginning_of_day..).count,
        users_30d: User.where(created_at: (as_of - 29).beginning_of_day..).count,
        active_users_7d: active_users((as_of - 6)),
        active_users_30d: active_users((as_of - 29)),
        admins_total: User.where(admin: true).count,
        savings_count: Saving.count,
        savings_total: Saving.sum(:amount).to_d,
        savings_today_count: Saving.where(saved_on: as_of).count,
        savings_today_total: Saving.where(saved_on: as_of).sum(:amount).to_d,
        savings_7d_total: Saving.where(saved_on: (as_of - 6)..as_of).sum(:amount).to_d,
        goals_count: Goal.count,
        goals_achieved_count: goals_achieved_count,
        categories_count: Category.count,
        push_users: PushSubscription.distinct.count(:user_id),
        push_devices: PushSubscription.count,
        signups_by_day: fill_days(User.where(created_at: window_start.beginning_of_day..).group("DATE(created_at)").count),
        savings_by_day: fill_days(Saving.where(saved_on: window_start..as_of).group(:saved_on).sum(:amount)),
        top_categories: top_categories,
        latest_users: User.with_attached_avatar.order(created_at: :desc).limit(8),
        latest_savings: Saving.includes(:user, :category).order(created_at: :desc).limit(10)
      )
    end

    private

    attr_reader :as_of

    def window_start
      as_of - (DAYS - 1)
    end

    # Usuários com alguma economia registrada (created_at) desde a data.
    def active_users(since)
      Saving.where(created_at: since.beginning_of_day..).distinct.count(:user_id)
    end

    # Metas cujo total vinculado alcançou o alvo, em uma query.
    def goals_achieved_count
      Goal.joins(:savings).group("goals.id", "goals.target_amount")
          .having("SUM(savings.amount) >= goals.target_amount").count.size
    end

    # Categorias somadas pelo nome (cada usuário tem as suas), últimos 30 dias.
    def top_categories
      Saving.joins(:category).where(saved_on: window_start..as_of)
            .group("categories.name").sum(:amount)
            .sort_by { |_, total| -total }.first(8)
            .map { |name, total| [ name, total.to_d ] }
    end

    def fill_days(counts)
      normalized = counts.transform_keys { |k| k.respond_to?(:to_date) ? k.to_date : Date.parse(k.to_s) }
      (window_start..as_of).to_h { |day| [ day, normalized.fetch(day, 0) ] }
    end
  end
end
