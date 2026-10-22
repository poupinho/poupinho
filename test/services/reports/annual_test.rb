require "test_helper"

module Reports
  class AnnualTest < ActiveSupport::TestCase
    test "aggregates the current year from January (user has older savings) up to the current month" do
      report = Annual.call(user: users(:one), year: Date.current.year)
      # users(:one) tem economia no ano passado, então o ano corrente começa em janeiro.
      assert_equal Date.current.beginning_of_year, report.first_month
      assert_equal Date.current.month, report.rows.size
      assert_equal Date.current.beginning_of_month, report.rows.last.month
      assert_equal users(:one).savings.on_year(Date.current.year).sum(:amount), report.total
      assert_equal report.total, report.rows.sum(&:total)
      assert_in_delta 100.0, report.rows.sum(&:share), 0.5
      assert_equal (report.total / Date.current.month).round(2), report.monthly_average
    end

    test "previous year starts at the first saving month and averages over the active months" do
      report = Annual.call(user: users(:one), year: Date.current.year - 1)
      assert_equal BigDecimal("100"), report.total
      assert_equal 6, report.first_month.month
      assert_equal 7, report.rows.size # junho..dezembro
      assert_equal (BigDecimal("100") / 7).round(2), report.monthly_average
      assert_equal 6, report.best_month[:month].month
    end

    test "a user who started this month sees a single month" do
      user = users(:two)
      user.savings.delete_all
      user.savings.create!(amount: 10, saved_on: Date.current)
      report = Annual.call(user: user, year: Date.current.year)
      assert_equal 1, report.rows.size
      assert_equal Date.current.beginning_of_month, report.first_month
      assert_equal BigDecimal("10"), report.monthly_average
    end

    test "years without data have no months" do
      report = Annual.call(user: users(:one), year: 2005)
      assert_equal 0, report.total
      assert_nil report.best_month
      assert_nil report.first_month
      assert_empty report.rows
      assert_equal 0, report.monthly_average
      assert_empty report.by_category
    end
  end
end
