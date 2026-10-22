# Roda a cada hora (config/recurring.yml) e dispara os lembretes da hora corrente (fuso de Brasília).
class DailyReminderJob < ApplicationJob
  queue_as :default

  def perform(hour = Time.current.hour)
    Reminders::Daily.call(hour: hour)
  end
end
