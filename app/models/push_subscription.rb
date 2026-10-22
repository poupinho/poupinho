class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: true, length: { maximum: 1000 }
  validates :p256dh, :auth, presence: true
end
