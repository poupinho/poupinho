require "test_helper"

module Simulations
  class ProjectionTest < ActiveSupport::TestCase
    test "projects saved amounts for every horizon" do
      result = Projection.call(daily: 10)
      assert_equal %i[month year five_years ten_years], result.rows.map(&:key)
      assert_equal BigDecimal("304.17"), result.monthly
      assert_equal BigDecimal("3650.00"), result[:year].saved
      assert_equal BigDecimal("36500.00"), result[:ten_years].saved
    end

    test "invested value compounds monthly contributions" do
      result = Projection.call(daily: 10, monthly_rate: "0.01")
      assert_equal result.monthly, result[:month].invested
      assert_operator result[:year].invested, :>, result[:year].saved
      # 304.17 × ((1,01^12 − 1) / 0,01) ≈ 3.857,55
      assert_in_delta 3857.55, result[:year].invested.to_f, 0.05
    end

    test "zero rate keeps invested equal to saved" do
      result = Projection.call(daily: 5, monthly_rate: 0)
      result.rows.each { |row| assert_equal row.saved, row.invested }
    end

    test "values are BigDecimal" do
      result = Projection.call(daily: "7.5")
      assert_kind_of BigDecimal, result[:year].saved
      assert_kind_of BigDecimal, result[:year].invested
    end
  end
end
