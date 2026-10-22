require "test_helper"

class AnalyticsTest < ActionDispatch::IntegrationTest
  test "analytics script is off without GA_MEASUREMENT_ID" do
    with_env("GA_MEASUREMENT_ID" => nil) do
      get root_path
      assert_select "script[src*='googletagmanager']", count: 0
      assert_no_match "gtag", response.body
      assert_select ".ec-cookie-banner", count: 0
    end
  end

  test "analytics script is on with GA_MEASUREMENT_ID, on public and authenticated pages" do
    with_env("GA_MEASUREMENT_ID" => "G-TEST123") do
      get root_path
      assert_select "script[async][src='https://www.googletagmanager.com/gtag/js?id=G-TEST123']"
      assert_match "gtag('config', 'G-TEST123')", response.body
      assert_match "gtag('consent', 'default', {", response.body
      assert_match "analytics_storage: 'denied'", response.body
      assert_select ".ec-cookie-banner[data-controller=cookie-consent][hidden]", text: /Google Analytics/
      assert_select ".ec-cookie-banner a[href=?]", privacy_path
      assert_select ".ec-cookie-banner button[data-action='cookie-consent#accept']", text: "Aceitar"
      assert_select ".ec-cookie-banner button[data-action='cookie-consent#decline']", text: "Recusar"

      sign_in_as users(:one)
      get dashboard_path
      assert_select "script[src='https://www.googletagmanager.com/gtag/js?id=G-TEST123']"
    end
  end

  private

  def with_env(values)
    previous = values.keys.to_h { |key| [ key, ENV[key] ] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
