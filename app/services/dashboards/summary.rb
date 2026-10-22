module Dashboards
  # Calcula os KPIs e as séries dos gráficos do dashboard para um usuário.
  #
  # Todos os valores monetários são BigDecimal.
  class Summary
    Result = Struct.new(
      :today_total,
      :month_total,
      :year_total,
      :all_time_total,
      :month_count,
      :monthly_goal,
      :goal_progress,
      :current_streak,
      :biggest_amount,
      :by_month,
      :by_category,
      :by_day,
      :recent,
      keyword_init: true
    )

    RECENT_LIMIT = 5

    def self.call(user:, as_of: Date.current)
      new(user: user, as_of: as_of).call
    end

    def initialize(user:, as_of:)
      @user = user
      @as_of = as_of
    end

    def call
      Result.new(
        today_total: today_total,
        month_total: month_total,
        year_total: year_total,
        all_time_total: all_time_total,
        month_count: month_scope.count,
        monthly_goal: user.monthly_goal,
        goal_progress: goal_progress,
        current_streak: current_streak,
        biggest_amount: biggest_amount,
        by_month: by_month,
        by_category: by_category,
        by_day: by_day,
        recent: savings.recent.includes(:category).limit(RECENT_LIMIT)
      )
    end

    private

    attr_reader :user, :as_of

    def savings
      user.savings
    end

    def month_scope
      @month_scope ||= savings.on_month(as_of)
    end

    def today_total
      savings.where(saved_on: as_of).sum(:amount).to_d
    end

    def month_total
      @month_total ||= month_scope.sum(:amount).to_d
    end

    def year_total
      savings.on_year(as_of.year).sum(:amount).to_d
    end

    def all_time_total
      savings.sum(:amount).to_d
    end

    # Percentual da meta mensal já atingido (0..100+), ou nil sem meta.
    def goal_progress
      return nil if user.monthly_goal.blank? || user.monthly_goal <= 0
      ((month_total / user.monthly_goal) * 100).floor
    end

    # Dias consecutivos (terminando hoje ou ontem) com ao menos uma economia.
    def current_streak
      days = savings.where(saved_on: (as_of - 365)..as_of).distinct.pluck(:saved_on).to_set
      return 0 if days.empty?

      cursor = days.include?(as_of) ? as_of : as_of - 1
      streak = 0
      while days.include?(cursor)
        streak += 1
        cursor -= 1
      end
      streak
    end

    # Maior economia registrada até hoje (0 sem registros).
    def biggest_amount
      savings.maximum(:amount).to_d
    end

    def by_month
      start_date = as_of.beginning_of_month - 11.months
      end_date = as_of.end_of_month
      savings.where(saved_on: start_date..end_date)
             .group_by_month(:saved_on, range: start_date..end_date)
             .sum(:amount)
             .transform_values(&:to_d)
    end

    def by_category
      totals = month_scope.group(:category_id).sum(:amount)
      categories = user.categories.index_by(&:id)
      totals.map { |category_id, total| [ categories[category_id], total.to_d ] }
            .sort_by { |_, total| -total }
    end

    def by_day
      range = as_of.beginning_of_month..as_of.end_of_month
      month_scope.group_by_day(:saved_on, range: range)
                 .sum(:amount)
                 .transform_values(&:to_d)
    end
  end
end
