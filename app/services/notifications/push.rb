module Notifications
  # Envia uma notificação Web Push para todas as assinaturas de um usuário.
  # Assinaturas expiradas/inválidas (404/410) são apagadas. Sem chaves VAPID, não envia.
  class Push
    def self.configured?
      ENV["VAPID_PUBLIC_KEY"].present? && ENV["VAPID_PRIVATE_KEY"].present?
    end

    def self.call(user:, title:, body:, url: "/dashboard", tag: nil)
      new(user: user, title: title, body: body, url: url, tag: tag).call
    end

    def initialize(user:, title:, body:, url:, tag:)
      @user, @title, @body, @url, @tag = user, title, body, url, tag
    end

    # Retorna quantas assinaturas receberam a notificação.
    def call
      return 0 unless self.class.configured?

      user.push_subscriptions.to_a.count { |subscription| deliver(subscription) }
    end

    private

    attr_reader :user, :title, :body, :url, :tag

    def deliver(subscription)
      WebPush.payload_send(
        message: payload,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        ttl: 6.hours.to_i,
        urgency: "normal",
        vapid: {
          subject: ENV.fetch("VAPID_SUBJECT", "https://poupinho.com.br"),
          public_key: ENV["VAPID_PUBLIC_KEY"],
          private_key: ENV["VAPID_PRIVATE_KEY"]
        }
      )
      true
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      subscription.destroy
      false
    rescue WebPush::Error => e
      Rails.logger.warn("Web Push falhou para subscription #{subscription.id}: #{e.class} #{e.message}")
      false
    end

    def payload
      { title: title, body: body, url: url, tag: tag, icon: "/icon-192.png", badge: "/icon-192.png" }.compact.to_json
    end
  end
end
