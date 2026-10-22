require "test_helper"

class ShareQrTest < ActionDispatch::IntegrationTest
  test "the qr short url sends anyone to the landing, tagged as coming from the card" do
    get "/qr"
    assert_redirected_to root_path(utm_source: "share_card", utm_medium: "qrcode", utm_campaign: "poupinho")

    follow_redirect!
    assert_response :success
  end

  test "the card carries the qr matrix and the url it points to" do
    sign_in_as users(:one)

    get dashboard_path
    assert_response :success

    card = css_select("#share-card-modal").first
    assert card, "modal do card não renderizou"
    assert card["data-share-card-qr-value"].present?, "card sem a matriz do QR"
    assert card["data-share-card-qr-hint-value"].present?, "card sem a legenda do QR"
    assert_equal Sharing::QrCode.call("http://www.example.com/qr"), card["data-share-card-qr-value"]
  end
end
