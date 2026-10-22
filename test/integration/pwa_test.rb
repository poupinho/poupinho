require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "manifest is installable: name, icons 192/512, maskable, start_url and shortcuts" do
    get pwa_manifest_path(format: :json)
    assert_response :success
    manifest = JSON.parse(response.body)
    assert_equal "Poupinho", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "/dashboard", manifest["start_url"]
    sizes = manifest["icons"].map { |i| i["sizes"] }
    assert_includes sizes, "192x192"
    assert_includes sizes, "512x512"
    assert manifest["icons"].any? { |i| i["purpose"] == "maskable" }
    assert_equal "/savings/new", manifest["shortcuts"].first["url"]
  end

  test "service worker is served as javascript with offline fallback" do
    get pwa_service_worker_path(format: :js)
    assert_response :success
    assert_match %r{javascript}, response.media_type
    assert_includes response.body, "/offline.html"
    assert_includes response.body, "addEventListener(\"fetch\""
  end

  test "icons and offline page exist as static files" do
    %w[icon.png icon-192.png icon-maskable.png apple-touch-icon.png icon.svg offline.html].each do |file|
      assert File.exist?(Rails.root.join("public", file)), "public/#{file} missing"
    end
  end

  test "layout links manifest, apple touch icon and registers the service worker" do
    sign_in_as users(:one)
    get dashboard_path
    assert_select "link[rel=manifest][href=?]", pwa_manifest_path(format: :json)
    assert_select "link[rel=apple-touch-icon][href='/apple-touch-icon.png']"
    assert_select "meta[name=theme-color]", minimum: 1
    assert_includes response.body, "serviceWorker.register"
    assert_select "[data-controller='pwa-install'] .ec-install-banner"
    assert_select ".ec-offline-bar[data-controller='network-status']"
  end

  test "login page also renders the pwa partial" do
    get new_session_path
    assert_select ".ec-install-banner"
  end
end
