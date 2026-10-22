module Reminders
  # Lembrete "dá uma poupadinha", automático: para quem tem assinatura push e ainda não
  # registrou economia hoje, na hora em que costuma registrar (Reminders::BestHour),
  # no máximo uma vez por dia. O texto muda conforme a sequência.
  class Daily
    def self.call(hour: Time.current.hour, as_of: Date.current)
      new(hour: hour, as_of: as_of).call
    end

    def initialize(hour:, as_of:)
      @hour = hour
      @as_of = as_of
    end

    # Retorna o número de usuários notificados.
    def call
      candidates.find_each.count do |user|
        next false if BestHour.for(user, as_of: as_of) != hour
        next false if user.savings.exists?(saved_on: as_of)

        streak = Dashboards::Summary.call(user: user, as_of: as_of).current_streak
        sent = Notifications::Push.call(user: user, title: I18n.t("reminders.title"), body: body_for(user, streak),
                                        url: "/savings/new", tag: "poupadinha-#{as_of}").positive?
        user.update_column(:last_reminded_on, as_of) if sent
        sent
      end
    end

    private

    attr_reader :hour, :as_of

    def candidates
      User.where(id: PushSubscription.select(:user_id))
          .where("last_reminded_on IS NULL OR last_reminded_on < ?", as_of)
    end

    def body_for(user, streak)
      if streak.positive?
        I18n.t("reminders.streak", name: user.first_name, count: streak)
      else
        I18n.t("reminders.messages").sample
      end
    end
  end
end
