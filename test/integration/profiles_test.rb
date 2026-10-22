require "test_helper"

class ProfilesTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup { sign_in_as users(:one) }

  test "edit shows the level card, breakdown, rules and ladder" do
    get edit_profile_path
    assert_select ".ec-level-card strong", text: "Iniciante"
    assert_select ".ec-level-card", text: /73 pontos no total/
    assert_select ".ec-level-list li", text: /Economias registradas.*40/m
    assert_select ".ec-level-rules li", minimum: 5
    assert_select ".ec-level-ladder li.is-current", text: /Iniciante/
    assert_select ".ec-level-ladder li", count: 7
  end

  test "reminders section and dashboard banner appear only when push is configured" do
    with_env("VAPID_PUBLIC_KEY" => nil, "VAPID_PRIVATE_KEY" => nil) do
      get edit_profile_path
      assert_select ".ec-form-section h2", text: "Lembretes", count: 0
      get dashboard_path
      assert_select ".ec-push-banner", count: 0
    end

    with_env("VAPID_PUBLIC_KEY" => "pub", "VAPID_PRIVATE_KEY" => "priv") do
      get edit_profile_path
      assert_select ".ec-form-section h2", text: "Lembretes"
      assert_select ".ec-push[data-controller=push] [data-push-target=enable]"
      assert_select "select[name='user[reminder_hour]']", count: 0

      get dashboard_path
      assert_select ".ec-push-banner[data-controller=push][data-push-mode-value=banner][hidden]"
    end
  end

  test "edit shows the form with current goal" do
    get edit_profile_path
    assert_response :success
    assert_select "input[name='user[monthly_goal]'][value='200,00']"
  end

  test "updates name and goal without touching the password" do
    patch profile_path, params: { user: { name: "Ana Paula", monthly_goal: "350.00", password: "", password_confirmation: "" } }
    assert_redirected_to dashboard_path
    user = users(:one).reload
    assert_equal "Ana Paula", user.name
    assert_equal BigDecimal("350"), user.monthly_goal
    assert user.authenticate("password")
  end

  test "updates password when provided" do
    patch profile_path, params: { user: { password: "novasenha", password_confirmation: "novasenha" } }
    assert users(:one).reload.authenticate("novasenha")
  end

  test "renders errors for invalid data" do
    patch profile_path, params: { user: { email_address: "invalido" } }
    assert_response :unprocessable_content
  end

  test "shows initials until a photo is uploaded, then the photo in the topbar" do
    get edit_profile_path
    assert_select ".ec-avatar-field .ec-avatar.ec-avatar-lg[data-initials=A]", text: "A"
    assert_select "input[type=file][name='user[avatar]'][accept*='image/jpeg']"
    assert_select "input[name='user[remove_avatar]']", count: 0

    patch profile_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png") } }
    assert_redirected_to dashboard_path
    assert users(:one).reload.avatar.attached?

    get dashboard_path
    assert_select ".ec-user-menu .ec-avatar img[alt=Ana][src*='/rails/active_storage/representations/']"
    get edit_profile_path
    assert_select ".ec-avatar-field .ec-avatar-lg img"
    assert_select "input[type=checkbox][name='user[remove_avatar]']"
  end

  test "removes the photo when asked, unless a new one is sent" do
    users(:one).avatar.attach(io: file_fixture("avatar.png").open, filename: "mine.png", content_type: "image/png")

    perform_enqueued_jobs do
      patch profile_path, params: { user: { remove_avatar: "1", avatar: fixture_file_upload("avatar.jpg", "image/jpeg") } }
    end
    assert_equal "avatar.jpg", users(:one).reload.avatar.filename.to_s

    perform_enqueued_jobs do
      patch profile_path, params: { user: { remove_avatar: "1" } }
    end
    assert_redirected_to dashboard_path
    assert_not users(:one).reload.avatar.attached?
  end

  test "rejects files that are not images" do
    patch profile_path, params: { user: { avatar: fixture_file_upload("not_image.txt", "text/plain") } }
    assert_response :unprocessable_content
    assert_select ".alert-danger li", text: /Foto de perfil deve ser uma imagem/
    assert_not users(:one).reload.avatar.attached?
  end
end
