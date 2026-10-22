require "test_helper"

module Admin
  class OverviewTest < ActiveSupport::TestCase
    test "aggregates users, savings and goals across the system" do
      o = Overview.call
      assert_equal User.count, o.users_total
      assert_equal 1, o.admins_total
      assert_equal Saving.count, o.savings_count
      assert_equal Saving.sum(:amount).to_d, o.savings_total
      assert_equal 3, o.savings_today_count # today_lunch, today_transport, other_user
      assert_equal Goal.count, o.goals_count
      assert_equal 0, o.goals_achieved_count
      assert_equal 2, o.active_users_7d
      assert_equal 30, o.savings_by_day.size
      assert_equal 30, o.signups_by_day.size
      assert_equal Saving.where(saved_on: Date.current).sum(:amount).to_d, o.savings_by_day[Date.current]
      assert o.top_categories.any? { |name, _| name == "Almoço" }
    end

    test "counts achieved goals" do
      users(:one).savings.create!(amount: 60, saved_on: Date.current, goal: goals(:trip))
      assert_equal 1, Overview.call.goals_achieved_count
    end
  end
end
