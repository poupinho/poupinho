module Simulations
  # Projeta quanto uma economia diária vira ao longo do tempo.
  # Para cada horizonte, calcula o valor simplesmente guardado (dias × valor)
  # e o valor investido, com aportes mensais rendendo juros compostos.
  class Projection
    DAYS_PER_MONTH = BigDecimal("365") / 12
    DEFAULT_MONTHLY_RATE = BigDecimal("0.008") # ≈ 0,8% ao mês
    EXAMPLE_DAILY_AMOUNTS = [ 5, 10, 20, 50 ].map { |v| BigDecimal(v.to_s) }.freeze

    HORIZONS = [
      { key: :month, months: 1 },
      { key: :year, months: 12 },
      { key: :five_years, months: 60 },
      { key: :ten_years, months: 120 }
    ].freeze

    Row = Struct.new(:key, :months, :saved, :invested, keyword_init: true)
    Result = Struct.new(:daily, :monthly, :monthly_rate, :rows, keyword_init: true) do
      def [](key)
        rows.find { |row| row.key == key }
      end
    end

    def self.call(daily:, monthly_rate: DEFAULT_MONTHLY_RATE)
      new(daily: daily, monthly_rate: monthly_rate).call
    end

    def initialize(daily:, monthly_rate: DEFAULT_MONTHLY_RATE)
      @daily = daily.to_d
      @monthly_rate = monthly_rate.to_d
    end

    def call
      Result.new(
        daily: daily,
        monthly: monthly.round(2),
        monthly_rate: monthly_rate,
        rows: HORIZONS.map { |h| row(h[:key], h[:months]) }
      )
    end

    private

    attr_reader :daily, :monthly_rate

    def monthly
      daily * DAYS_PER_MONTH
    end

    def row(key, months)
      Row.new(
        key: key,
        months: months,
        saved: (monthly * months).round(2),
        invested: future_value(months).round(2)
      )
    end

    # Valor futuro de aportes mensais constantes (série uniforme postecipada).
    def future_value(months)
      return monthly * months if monthly_rate.zero?

      monthly * (((1 + monthly_rate)**months - 1) / monthly_rate)
    end
  end
end
