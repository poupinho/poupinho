require "test_helper"

module Goals
  class OverviewTest < ActiveSupport::TestCase
    setup { @rows = Overview.call(user: users(:one)) }

    test "returns one row per goal, ordered by position" do
      assert_equal [ goals(:trip), goals(:emergency) ], @rows.map(&:goal)
    end

    test "sums only the savings linked to each goal" do
      assert_equal BigDecimal("43.50"), @rows.first.saved
      assert_equal BigDecimal("0"), @rows.second.saved
    end

    test "ignores other users' savings and goals" do
      rows = Overview.call(user: users(:two))
      assert_equal [ goals(:other_user_goal) ], rows.map(&:goal)
      assert_equal BigDecimal("0"), rows.first.saved
    end

    test "progress, remaining and achieved" do
      row = @rows.first
      assert_equal 43, row.progress
      assert_equal 43, row.progress_capped
      assert_equal BigDecimal("56.50"), row.remaining
      assert_not row.achieved?
    end

    test "progress is capped for display once the goal is reached" do
      goals(:trip).update!(target_amount: 20)
      row = Overview.call(user: users(:one).reload).first
      assert_equal 217, row.progress
      assert_equal 100, row.progress_capped
      assert_equal BigDecimal("0"), row.remaining
      assert row.achieved?
    end

    test "overdue only when the deadline passed and the goal was not reached" do
      goals(:trip).update!(deadline: Date.current - 1)
      assert Overview.call(user: users(:one).reload).first.overdue?

      goals(:trip).update!(target_amount: 10)
      assert_not Overview.call(user: users(:one).reload).first.overdue?
    end
  end
end
