require "test_helper"

module Dashboards
  class SummaryTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @summary = Summary.call(user: @user)
    end

    test "totals for today, month, year and all time" do
      assert_equal BigDecimal("28.30"), @summary.today_total
      assert_equal @user.savings.on_month(Date.current).sum(:amount), @summary.month_total
      assert_equal @user.savings.on_year(Date.current.year).sum(:amount), @summary.year_total
      assert_equal BigDecimal("153.30"), @summary.all_time_total
    end

    test "ignores other users' savings" do
      assert_equal BigDecimal("50"), Summary.call(user: users(:two)).today_total
      assert_not_includes @summary.recent, savings(:other_user)
    end

    test "goal progress uses monthly goal" do
      expected = ((@summary.month_total / BigDecimal("200")) * 100).floor
      assert_equal expected, @summary.goal_progress
      assert_nil Summary.call(user: users(:two)).goal_progress
    end

    test "biggest amount is the largest saving ever" do
      assert_equal BigDecimal("100"), @summary.biggest_amount
      @user.savings.destroy_all
      assert_equal BigDecimal("0"), Summary.call(user: @user).biggest_amount
    end

    test "current streak counts consecutive days ending today" do
      assert_equal 2, @summary.current_streak
    end

    test "streak is zero without recent savings" do
      @user.savings.destroy_all
      assert_equal 0, Summary.call(user: @user).current_streak
    end

    test "by_month covers the last 12 months" do
      assert_equal 12, @summary.by_month.size
      assert_equal @summary.month_total, @summary.by_month.values.last
    end

    test "by_category sorts categories by total desc" do
      names = @summary.by_category.map { |cat, _| cat.name }
      assert_equal %w[Almoço Transporte], names
    end

    test "by_day has one entry per day of the month" do
      assert_equal Date.current.end_of_month.day, @summary.by_day.size
    end
  end
end
