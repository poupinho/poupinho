module Reports
  # Consolida as economias de um usuário em um ano: totais por mês e por categoria.
  #
  # Os meses vão do primeiro mês com economia (em qualquer ano, limitado ao ano
  # pedido) até o mês atual (ano corrente) ou dezembro (anos anteriores). Assim
  # quem começou em setembro não vê oito meses zerados, e a média mensal considera
  # só os meses ativos.
  class Annual
    MonthRow = Struct.new(:month, :count, :total, :share, keyword_init: true)

    Result = Struct.new(
      :year,
      :total,
      :count,
      :monthly_average,
      :best_month,
      :rows,
      :by_category,
      :first_month,
      keyword_init: true
    )

    def self.call(user:, year:)
      new(user: user, year: year).call
    end

    def initialize(user:, year:)
      @user = user
      @year = year.to_i
    end

    def call
      Result.new(
        year: year,
        total: total,
        count: scope.count,
        monthly_average: monthly_average,
        best_month: best_month,
        rows: rows,
        by_category: by_category,
        first_month: months.first
      )
    end

    private

    attr_reader :user, :year

    def scope
      @scope ||= user.savings.on_year(year)
    end

    def totals_by_month
      @totals_by_month ||= scope.group("date_trunc('month', saved_on)::date").sum(:amount)
                                .transform_keys { |d| d.to_date }
    end

    def counts_by_month
      @counts_by_month ||= scope.group("date_trunc('month', saved_on)::date").count
                                .transform_keys { |d| d.to_date }
    end

    def total
      @total ||= scope.sum(:amount).to_d
    end

    # Primeiro dia de cada mês coberto pelo relatório (pode ser vazio).
    def months
      @months ||= begin
        first = first_month_of_year
        last = last_month_of_year
        first && last && first <= last ? (first..last).select { |d| d.day == 1 } : []
      end
    end

    def first_month_of_year
      earliest = user.savings.minimum(:saved_on)
      return nil if earliest.nil?
      return Date.new(year, 1, 1) if earliest.year < year
      return nil if earliest.year > year
      earliest.beginning_of_month
    end

    def last_month_of_year
      return Date.new(year, 12, 1) if year < Date.current.year
      return nil if year > Date.current.year
      Date.current.beginning_of_month
    end

    def monthly_average
      months.empty? ? BigDecimal("0") : (total / months.size).round(2)
    end

    def best_month
      month, amount = totals_by_month.max_by { |_, v| v }
      month && { month: month, total: amount.to_d }
    end

    def rows
      months.map do |first|
        amount = totals_by_month.fetch(first, 0).to_d
        MonthRow.new(
          month: first,
          count: counts_by_month.fetch(first, 0),
          total: amount,
          share: total.zero? ? 0 : ((amount / total) * 100).round(1)
        )
      end
    end

    def by_category
      categories = user.categories.index_by(&:id)
      scope.group(:category_id).sum(:amount)
           .map { |id, v| [ categories[id], v.to_d ] }
           .sort_by { |_, v| -v }
    end
  end
end
