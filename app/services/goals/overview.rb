module Goals
  # Carrega as metas do usuário já com o total economizado de cada uma,
  # em uma única query de agregação (sem N+1).
  #
  # Todos os valores monetários são BigDecimal.
  class Overview
    Row = Struct.new(:goal, :saved, keyword_init: true) do
      # Percentual atingido (0..100+); 0 quando a meta não tem alvo válido.
      def progress
        return 0 if goal.target_amount.blank? || goal.target_amount <= 0
        ((saved / goal.target_amount) * 100).floor
      end

      def progress_capped
        [ progress, 100 ].min
      end

      def remaining
        [ goal.target_amount - saved, BigDecimal("0") ].max
      end

      def achieved?
        saved >= goal.target_amount
      end

      # Prazo vencido e meta ainda não atingida.
      def overdue?
        goal.deadline.present? && goal.deadline < Date.current && !achieved?
      end
    end

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      totals = user.savings.where.not(goal_id: nil).group(:goal_id).sum(:amount)

      user.goals.map do |goal|
        Row.new(goal: goal, saved: totals.fetch(goal.id, 0).to_d)
      end
    end

    private

    attr_reader :user
  end
end
