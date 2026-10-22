require "test_helper"

class LegalTest < ActionDispatch::IntegrationTest
  test "privacy policy and terms are public" do
    get privacy_path
    assert_response :success
    assert_select "h1", text: "Política de Privacidade"
    assert_select "h2", text: "Dados que coletamos"
    assert_select "header.ec-topbar", count: 0

    get terms_path
    assert_response :success
    assert_select "h1", text: "Termos de Uso"
    assert_select "h2", text: "Não é aconselhamento financeiro"
  end

  test "landing footer links to the legal pages" do
    get root_path
    assert_select ".ec-landing-footer a[href=?]", privacy_path
    assert_select ".ec-landing-footer a[href=?]", terms_path
  end
end
