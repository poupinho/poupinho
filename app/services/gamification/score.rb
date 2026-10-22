module Gamification
  # Pontos e nível do usuário, derivados dos dados (economias, datas e metas):
  # nada é persistido, então editar ou excluir uma economia recalcula sozinho.
  #
  # Regras:
  #   +10 por economia registrada
  #   +1 a cada R$ 10 economizados (piso), no máximo +100 por economia
  #   marcos de sequência (3, 7, 14, 30, 60, 100 dias), uma vez por sequência
  #   +150 por meta atingida (saldo >= alvo)
  #   +20 pela primeira economia da conta
  class Score
    POINTS_PER_SAVING = 10
    AMOUNT_STEP = 10
    AMOUNT_CAP_PER_SAVING = 100
    FIRST_SAVING_BONUS = 20
    GOAL_ACHIEVED_BONUS = 150
    STREAK_MILESTONES = { 3 => 15, 7 => 50, 14 => 100, 30 => 200, 60 => 400, 100 => 800 }.freeze
    # [nível, pontos mínimos]
    LEVELS = [ [ 1, 0 ], [ 2, 100 ], [ 3, 300 ], [ 4, 700 ], [ 5, 1_500 ], [ 6, 3_000 ], [ 7, 6_000 ] ].freeze

    Result = Struct.new(
      :points, :level, :level_name, :level_floor, :next_level_points, :points_to_next, :progress_pct,
      :breakdown, :best_streak,
      keyword_init: true
    ) do
      def max_level?
        next_level_points.nil?
      end
    end

    def self.call(user:)
      new(user: user).call
    end

    def self.level_name(level)
      I18n.t("gamification.levels.#{level}")
    end

    def initialize(user:)
      @user = user
    end

    def call
      breakdown = {
        savings: savings_count * POINTS_PER_SAVING,
        amount: amount_points,
        streaks: streak_points,
        goals: achieved_goals_count * GOAL_ACHIEVED_BONUS,
        first_saving: savings_count.positive? ? FIRST_SAVING_BONUS : 0
      }
      points = breakdown.values.sum

      level, floor = LEVELS.reverse.find { |_, min| points >= min }
      next_level = LEVELS.find { |l, _| l == level + 1 }
      next_points = next_level&.last
      progress = next_points ? (((points - floor).to_f / (next_points - floor)) * 100).floor : 100

      Result.new(
        points: points,
        level: level,
        level_name: self.class.level_name(level),
        level_floor: floor,
        next_level_points: next_points,
        points_to_next: next_points ? next_points - points : 0,
        progress_pct: progress.clamp(0, 100),
        breakdown: breakdown,
        best_streak: streak_runs.max || 0
      )
    end

    private

    attr_reader :user

    def savings
      user.savings
    end

    def savings_count
      @savings_count ||= savings.count
    end

    # LEAST(FLOOR(amount / 10), 100) somado no banco, em uma query.
    def amount_points
      savings.sum(Arel.sql("LEAST(FLOOR(amount / #{AMOUNT_STEP}), #{AMOUNT_CAP_PER_SAVING})")).to_i
    end

    # Tamanho de cada sequência de dias consecutivos com economia, em toda a história.
    def streak_runs
      @streak_runs ||= begin
        dates = savings.distinct.order(:saved_on).pluck(:saved_on)
        runs = []
        dates.each do |date|
          if runs.any? && date == @last_date + 1
            runs[-1] += 1
          else
            runs << 1
          end
          @last_date = date
        end
        runs
      end
    end

    def streak_points
      streak_runs.sum do |length|
        STREAK_MILESTONES.sum { |days, bonus| length >= days ? bonus : 0 }
      end
    end

    def achieved_goals_count
      Goals::Overview.call(user: user).count(&:achieved?)
    end
  end
end
