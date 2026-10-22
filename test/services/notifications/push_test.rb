require "test_helper"

module Notifications
  class PushTest < ActiveSupport::TestCase
    setup do
      @env = { "VAPID_PUBLIC_KEY" => "pub", "VAPID_PRIVATE_KEY" => "priv" }
    end

    test "sends the payload to every subscription of the user" do
      users(:one).push_subscriptions.create!(endpoint: "https://push.example.com/one/desktop", p256dh: "k", auth: "a")
      sent = []
      stubbing(WebPush, :payload_send, ->(**args) { sent << args; true }) do
        with_env(@env) do
          assert_equal 2, Push.call(user: users(:one), title: "Oi", body: "Poupadinha?", url: "/savings/new")
        end
      end
      assert_equal 2, sent.size
      payload = JSON.parse(sent.first[:message])
      assert_equal "Oi", payload["title"]
      assert_equal "/savings/new", payload["url"]
      assert_equal "pub", sent.first[:vapid][:public_key]
    end

    test "drops expired subscriptions and survives other errors" do
      calls = 0
      failing = lambda do |**args|
        calls += 1
        raise WebPush::ExpiredSubscription.new(Struct.new(:code, :body).new("410", ""), "host") if args[:endpoint].end_with?("phone")
        raise WebPush::ResponseError.new(Struct.new(:code, :body).new("500", ""), "host")
      end
      users(:one).push_subscriptions.create!(endpoint: "https://push.example.com/one/desktop", p256dh: "k", auth: "a")
      stubbing(WebPush, :payload_send, failing) do
        with_env(@env) do
          assert_equal 0, Push.call(user: users(:one), title: "Oi", body: "x")
        end
      end
      assert_equal 2, calls
      assert_nil PushSubscription.find_by(endpoint: "https://push.example.com/one/phone")
      assert PushSubscription.exists?(endpoint: "https://push.example.com/one/desktop")
    end

    test "does nothing without VAPID keys" do
      with_env("VAPID_PUBLIC_KEY" => nil, "VAPID_PRIVATE_KEY" => nil) do
        assert_not Push.configured?
        assert_equal 0, Push.call(user: users(:one), title: "Oi", body: "x")
      end
    end
  end
end
