require "test_helper"

class GoogleSignInTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  IMAGE = "https://lh3.googleusercontent.com/a/abc=s96-c".freeze

  setup do
    OmniAuth.config.test_mode = true
    @auth = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "g-123",
                                   info: { email: "Maria@Example.com", name: "Maria Silva", image: IMAGE })
    OmniAuth.config.mock_auth[:google_oauth2] = @auth
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "button appears only when Google is configured" do
    with_env("GOOGLE_CLIENT_ID" => nil, "GOOGLE_CLIENT_SECRET" => nil) do
      get new_session_path
      assert_select "form.ec-auth-google-form", count: 0
    end
    with_env("GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret") do
      get new_session_path
      assert_select "form.ec-auth-google-form[action='/auth/google_oauth2'][method=post] button", text: /Continuar com Google/
      get new_registration_path
      assert_select "form.ec-auth-google-form", count: 1
    end
  end

  test "new Google account goes through phone and then goal onboarding" do
    assert_difference("User.count", 1) do
      post "/auth/google_oauth2"
      follow_redirect! # -> callback
    end
    user = User.find_by!(email_address: "maria@example.com")
    assert_equal "g-123", user.google_uid
    assert_equal "Maria Silva", user.name
    assert_nil user.phone
    assert_enqueued_with(job: GoogleAvatarJob, args: [ user, IMAGE ])
    assert_redirected_to onboarding_phone_path

    # Qualquer outra tela volta para o celular enquanto ele estiver vazio.
    get dashboard_path
    assert_redirected_to onboarding_phone_path

    get onboarding_phone_path
    assert_response :success
    assert_select "h1", text: "Só falta o seu celular"
    assert_select "input[name='user[phone]'][required][data-controller=phone-mask]"

    patch onboarding_phone_path, params: { user: { phone: "(11) 1234-5678" } } # fixo: inválido
    assert_response :unprocessable_content
    assert_select ".alert-danger li", text: /Celular/

    patch onboarding_phone_path, params: { user: { phone: "(11) 91234-5678" } }
    assert_redirected_to new_goal_path(onboarding: 1)
    assert_equal "11912345678", user.reload.phone

    get dashboard_path
    assert_response :success
  end

  test "existing account with the same email is linked and signs in directly" do
    @auth.uid = "g-one"
    @auth.info.email = "one@example.com"
    assert_no_difference("User.count") do
      post "/auth/google_oauth2"
      follow_redirect!
    end
    assert_redirected_to dashboard_path
    assert_equal "g-one", users(:one).reload.google_uid
    assert_enqueued_with(job: GoogleAvatarJob, args: [ users(:one), IMAGE ])

    # Próximo login: pelo uid, sem baixar a foto de novo.
    delete session_path
    assert_no_enqueued_jobs(only: GoogleAvatarJob) do
      post "/auth/google_oauth2"
      follow_redirect!
    end
    assert_redirected_to dashboard_path
  end

  test "does not fetch the Google photo when the user already has one or Google sent none" do
    @auth.uid = "g-one"
    @auth.info.email = "one@example.com"
    users(:one).avatar.attach(io: file_fixture("avatar.png").open, filename: "mine.png", content_type: "image/png")
    assert_no_enqueued_jobs(only: GoogleAvatarJob) do
      post "/auth/google_oauth2"
      follow_redirect!
    end

    delete session_path
    @auth.uid = "g-two"
    @auth.info.email = "two@example.com"
    @auth.info.image = nil
    assert_no_enqueued_jobs(only: GoogleAvatarJob) do
      post "/auth/google_oauth2"
      follow_redirect!
    end
  end

  test "failure redirects to the sign in page with a message" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
    post "/auth/google_oauth2"
    follow_redirect!
    follow_redirect!
    assert_redirected_to new_session_path
  end
end
