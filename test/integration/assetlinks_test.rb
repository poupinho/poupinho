require "test_helper"

class AssetlinksTest < ActionDispatch::IntegrationTest
  FINGERPRINT = "AB:CD:EF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC".freeze

  test "is a 404 while no signing certificate is configured" do
    with_env("ANDROID_FINGERPRINTS" => nil) do
      get "/.well-known/assetlinks.json"
    end
    assert_response :not_found
  end

  test "serves the statement the Android verifier expects" do
    with_env("ANDROID_FINGERPRINTS" => FINGERPRINT) do
      get "/.well-known/assetlinks.json"
    end
    assert_response :success

    statement = JSON.parse(response.body).sole
    assert_equal [ "delegate_permission/common.handle_all_urls" ], statement["relation"]
    assert_equal "android_app", statement["target"]["namespace"]
    assert_equal "br.com.poupinho", statement["target"]["package_name"]
    assert_equal [ FINGERPRINT ], statement["target"]["sha256_cert_fingerprints"]
  end

  test "carries both certificates, the upload key and the one Play signs with" do
    other = FINGERPRINT.tr("A", "B")
    with_env("ANDROID_FINGERPRINTS" => " #{FINGERPRINT} , #{other} ,") do
      get "/.well-known/assetlinks.json"
    end

    assert_equal [ FINGERPRINT, other ], JSON.parse(response.body).sole["target"]["sha256_cert_fingerprints"]
  end

  test "is public: the Android verifier fetches it without any session" do
    with_env("ANDROID_FINGERPRINTS" => FINGERPRINT) do
      get "/.well-known/assetlinks.json"
    end
    assert_response :success
    assert_equal "application/json", response.media_type
  end
end
