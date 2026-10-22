module Reminders
  # Hora do dia (fuso da app) em que o usuário costuma registrar economias: a hora
  # mais frequente dos registros dos últimos 60 dias, limitada à janela 8h..21h.
  # Sem histórico suficiente, usa o padrão das 20h.
  class BestHour
    DEFAULT = 20
    WINDOW = 8..21
    MIN_SAMPLES = 3
    LOOKBACK = 60

    def self.for(user, as_of: Date.current)
      new(user, as_of: as_of).call
    end

    def initialize(user, as_of:)
      @user = user
      @as_of = as_of
    end

    def call
      hours = user.savings.where(created_at: (as_of - LOOKBACK).beginning_of_day..)
                  .pluck(:created_at).map { |t| t.in_time_zone.hour }
      return DEFAULT if hours.size < MIN_SAMPLES

      hour = hours.tally.max_by { |h, count| [ count, h ] }.first
      hour.clamp(WINDOW.min, WINDOW.max)
    end

    private

    attr_reader :user, :as_of
  end
end
