require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "unauthenticated request to dashboard redirects to login" do
    get "/dashboard"
    assert_redirected_to "/session/new"
  end

  test "unauthenticated request to root renders the landing page" do
    get "/"
    assert_response :success
    assert_select ".ec-landing"
  end

  test "sign in with valid credentials" do
    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to dashboard_url
    follow_redirect!
    assert_select "header.ec-topbar"
  end

  test "sign in with wrong password shows error" do
    post session_path, params: { email_address: users(:one).email_address, password: "errada" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select ".alert-danger", text: /incorretos/
  end

  test "sign out" do
    sign_in_as users(:one)
    delete session_path
    assert_redirected_to new_session_path
    get "/dashboard"
    assert_redirected_to "/session/new"
  end
end
