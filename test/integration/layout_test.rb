require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "authenticated pages render topbar, top nav and bottom nav" do
    get dashboard_path
    assert_select "header.ec-topbar .ec-brand", text: /Poupinho/
    %w[Início Histórico Metas Relatórios].each do |label|
      assert_select "nav.ec-topnav .nav-link", text: label
      assert_select "nav.ec-bottom-nav .nav-link", text: label
    end
    assert_select "nav.ec-topnav .nav-link", text: "Categorias"
    assert_select "nav.ec-bottom-nav .nav-link", text: "Categorias", count: 0
    assert_select "nav.ec-bottom-nav .ec-nav-add", text: /Adicionar/
    assert_select "nav.ec-topnav .nav-link.active", text: "Início"
    assert_select "aside.ec-sidebar", count: 0
  end

  test "bottom nav highlights the current section and the add link on the form" do
    get savings_path
    assert_select "nav.ec-bottom-nav .nav-link.active", text: "Histórico"

    get new_saving_path
    assert_select "nav.ec-bottom-nav .ec-nav-add.active", count: 1
  end

  test "user menu links to the profile and to the landing page" do
    get dashboard_path
    assert_select ".ec-user-menu .dropdown-item[href=?]", edit_profile_path
    assert_select ".ec-user-menu .dropdown-item[href=?]", tips_path
    assert_select ".ec-user-menu .dropdown-item[href=?]", admin_root_path
    assert_select ".ec-user-menu .dropdown-item[href=?]", root_path
    assert_select ".ec-user-menu .dropdown-item[href=?]", categories_path
  end

  test "authenticated pages carry noindex and the default social meta tags" do
    get dashboard_path
    assert_select "meta[name=robots][content='noindex, nofollow']"
    assert_select "link[rel=canonical]", count: 0
    assert_select "meta[property='og:image'][content$='/og-image.png']"
    assert_select "meta[name=description]"
  end

  test "theme toggle is present" do
    get dashboard_path
    assert_select "[data-controller='theme']"
    assert_select "[data-action*='theme#toggle']"
    assert_select "[data-theme-target='lightIcon']"
    assert_select "[data-theme-target='darkIcon']"
  end

  test "login page has no topbar or sidebar" do
    sign_out
    get new_session_path
    assert_response :success
    assert_select "header.ec-topbar", count: 0
    assert_select "nav.ec-bottom-nav", count: 0
    assert_select ".ec-auth-card"
  end

  test "pwa manifest is served" do
    get pwa_manifest_path(format: :json)
    assert_response :success
    assert_includes response.body, "Poupinho"
  end
end
