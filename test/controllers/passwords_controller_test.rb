require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "renders forgot password page" do
    get new_password_path
    assert_response :success
    assert_select "h2", text: /Esqueceu sua senha/
  end

  test "requesting a reset always redirects to login with a neutral message" do
    post passwords_path, params: { email_address: users(:one).email_address }
    assert_redirected_to new_session_path
    assert_enqueued_emails 1

    post passwords_path, params: { email_address: "nao-existe@example.com" }
    assert_redirected_to new_session_path
  end

  test "invalid token redirects with alert" do
    get edit_password_path("token-invalido")
    assert_redirected_to new_password_path
  end

  test "resets the password with a valid token" do
    user = users(:one)
    put password_path(user.password_reset_token), params: { password: "novasenha", password_confirmation: "novasenha" }
    assert_redirected_to new_session_path
    assert user.reload.authenticate("novasenha")
  end
end
