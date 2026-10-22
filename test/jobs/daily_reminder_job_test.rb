require "test_helper"

class DailyReminderJobTest < ActiveJob::TestCase
  test "delegates to Reminders::Daily with the given hour" do
    received = nil
    stubbing(Reminders::Daily, :call, ->(hour:) { received = hour; 0 }) do
      DailyReminderJob.perform_now(9)
    end
    assert_equal 9, received
  end
end
