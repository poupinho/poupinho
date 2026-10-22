require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  test "non-admin users are redirected and do not see the menu item" do
    sign_in_as users(:two)
    get admin_root_path
    assert_redirected_to dashboard_path
    get admin_users_path
    assert_redirected_to dashboard_path
    get dashboard_path
    assert_select ".ec-user-menu .dropdown-item[href=?]", admin_root_path, count: 0
  end

  test "requires sign in" do
    get admin_root_path
    assert_redirected_to new_session_path
  end

  test "admin sees the system overview" do
    sign_in_as users(:one)
    get admin_root_path
    assert_response :success
    assert_select "h1", text: "Painel do sistema"
    assert_select ".ec-tile", minimum: 8
    assert_select ".ec-tile-value", text: User.count.to_s
    assert_select ".ec-section-title", text: /Cadastros por dia/
    assert_select ".ec-admin-list .ec-list-item", minimum: 2
  end

  test "admin lists users with stats and searches by email" do
    sign_in_as users(:one)
    get admin_users_path
    assert_response :success
    assert_select ".ec-page-sub", text: "#{User.count} usuários"
    assert_select "tbody tr", count: User.count
    assert_select "tbody tr", text: /one@example.com.*4.*R\$ 153,30/m
    assert_select "tbody .badge", text: /Nível 1 · Iniciante/

    get admin_users_path(q: "two@")
    assert_select "tbody tr", count: 1
    assert_select "tbody tr", text: /two@example.com/
  end

  test "admin sees a user's detail" do
    sign_in_as users(:one)
    get admin_user_path(users(:two))
    assert_response :success
    assert_select "h1", text: /Bruno/
    assert_select ".ec-tile-value", text: /R\$ 50,00/
    assert_select ".ec-level-list li", text: /Notebook novo/
    assert_select ".ec-admin-list .ec-list-item", count: 1
  end
end
