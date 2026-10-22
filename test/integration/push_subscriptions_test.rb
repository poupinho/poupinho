require "test_helper"

class PushSubscriptionsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "creates or updates the subscription for the current user" do
    payload = { subscription: { endpoint: "https://push.example.com/new", keys: { p256dh: "pk", auth: "au" } } }
    assert_difference("PushSubscription.count", 1) do
      post push_subscription_path, params: payload, as: :json
    end
    assert_response :created
    sub = PushSubscription.find_by(endpoint: "https://push.example.com/new")
    assert_equal users(:one), sub.user

    # Mesmo endpoint de novo: atualiza em vez de duplicar.
    assert_no_difference("PushSubscription.count") do
      post push_subscription_path, params: payload.deep_merge(subscription: { keys: { auth: "au2" } }), as: :json
    end
    assert_equal "au2", sub.reload.auth
  end

  test "rejects an incomplete subscription" do
    post push_subscription_path, params: { subscription: { endpoint: "https://push.example.com/x", keys: { p256dh: "" } } }, as: :json
    assert_response :unprocessable_content
  end

  test "destroys only the current user's subscription by endpoint" do
    other = users(:two).push_subscriptions.create!(endpoint: "https://push.example.com/two", p256dh: "k", auth: "a")
    assert_difference("PushSubscription.count", -1) do
      delete push_subscription_path(endpoint: push_subscriptions(:one_phone).endpoint)
    end
    assert_response :no_content
    assert_no_difference("PushSubscription.count") do
      delete push_subscription_path(endpoint: other.endpoint)
    end
  end

  test "requires sign in" do
    Current.session = nil
    cookies.delete("session_id")
    post push_subscription_path, params: { subscription: { endpoint: "e", keys: { p256dh: "k", auth: "a" } } }, as: :json
    assert_response :redirect
  end
end
