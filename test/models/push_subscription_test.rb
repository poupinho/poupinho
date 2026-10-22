require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  test "requires endpoint and keys and keeps endpoints unique" do
    sub = users(:one).push_subscriptions.new(endpoint: "", p256dh: "", auth: "")
    assert_not sub.valid?
    assert sub.errors[:endpoint].any?
    assert sub.errors[:p256dh].any?
    assert sub.errors[:auth].any?

    dup = users(:two).push_subscriptions.new(endpoint: push_subscriptions(:one_phone).endpoint, p256dh: "k", auth: "a")
    assert_not dup.valid?
  end
end
