require "test_helper"

class RegistrationsTest < ActionDispatch::IntegrationTest
  test "renders the sign up page" do
    get new_registration_path
    assert_response :success
    assert_select "h2", text: "Criar conta"
  end

  test "creates an account, logs in and seeds categories" do
    assert_difference("User.count", 1) do
      post registration_path, params: { user: { name: "Nova", email_address: "nova@example.com", phone: "(11) 91234-5678",
                                                password: "segredo1", password_confirmation: "segredo1" } }
    end
    assert_redirected_to new_goal_path(onboarding: 1)
    follow_redirect!
    assert_select ".ec-onboarding-head h1", text: /Bem-vindo, Nova/
    assert_select "input[name=onboarding][value='1']"
    assert_select ".ec-form-actions a[href=?]", dashboard_path
    assert_select "a.ec-back", count: 0
    assert_equal User::DEFAULT_CATEGORIES.size, User.find_by(email_address: "nova@example.com").categories.count
  end

  test "phone is required on sign up and stored as digits" do
    assert_no_difference("User.count") do
      post registration_path, params: { user: { email_address: "sem@example.com", password: "segredo1", password_confirmation: "segredo1" } }
    end
    assert_response :unprocessable_content
    assert_select ".alert-danger li", text: /Celular/
    assert_select "#registration_phone[required][data-controller=phone-mask]"

    post registration_path, params: { user: { email_address: "com@example.com", phone: "(11) 91234-5678",
                                              password: "segredo1", password_confirmation: "segredo1" } }
    assert_equal "11912345678", User.find_by(email_address: "com@example.com").phone
  end

  test "shows errors on invalid sign up" do
    assert_no_difference("User.count") do
      post registration_path, params: { user: { email_address: "x", password: "1", password_confirmation: "2" } }
    end
    assert_response :unprocessable_content
    assert_select ".alert-danger li", minimum: 1
  end
end
