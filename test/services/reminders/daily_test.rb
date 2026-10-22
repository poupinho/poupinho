require "test_helper"

module Reminders
  class DailyTest < ActiveSupport::TestCase
    setup do
      @user = users(:one) # tem assinatura push (fixture) e economias hoje; sem histórico -> hora padrão 20h
    end

    test "skips users who already saved today" do
      calls = []
      stubbing(Notifications::Push, :call, ->(**args) { calls << args; 1 }) do
        assert_equal 0, Daily.call(hour: 20)
      end
      assert_empty calls
      assert_nil @user.reload.last_reminded_on
    end

    test "notifies at the user's usual hour, once a day, mentioning the streak" do
      @user.savings.where(saved_on: Date.current).delete_all # sobra a de ontem: sequência de 1 dia
      calls = []
      stubbing(Notifications::Push, :call, ->(**args) { calls << args; 1 }) do
        assert_equal 0, Daily.call(hour: 8)   # não é a hora habitual (padrão 20h)
        assert_equal 1, Daily.call(hour: 20)
        assert_equal 0, Daily.call(hour: 20)  # já lembrado hoje
      end
      assert_equal 1, calls.size
      assert_equal @user, calls.first[:user]
      assert_match(/sequência de 1 dias/, calls.first[:body])
      assert_equal "/savings/new", calls.first[:url]
      assert_equal Date.current, @user.reload.last_reminded_on
    end

    test "uses the hour the user usually saves at and a generic message without a streak" do
      @user.savings.delete_all
      # Histórico: registra sempre por volta das 12h (created_at), mas em dias antigos.
      5.times { |i| @user.savings.create!(amount: 1, saved_on: Date.current - 10 - i, created_at: (Date.current - 10 - i).in_time_zone.change(hour: 12)) }
      users(:two).push_subscriptions.destroy_all # sem assinatura -> ignorado
      calls = []
      stubbing(Notifications::Push, :call, ->(**args) { calls << args; 1 }) do
        assert_equal 0, Daily.call(hour: 20)
        assert_equal 1, Daily.call(hour: 12)
      end
      assert_equal 1, calls.size
      assert_includes I18n.t("reminders.messages"), calls.first[:body]
    end

    test "best hour falls back to 20h without enough history and stays within 8h..21h" do
      assert_equal 20, BestHour.for(users(:two))
      user = users(:two)
      user.savings.delete_all
      4.times { |i| user.savings.create!(amount: 1, saved_on: Date.current - i, created_at: (Date.current - i).in_time_zone.change(hour: 2)) }
      assert_equal 8, BestHour.for(user)
    end
  end
end
