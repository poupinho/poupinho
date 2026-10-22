require "test_helper"

class AccountDeletionTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "the profile offers the deletion, confirmed by typing the email" do
    sign_in_as @user
    get edit_profile_path
    assert_response :success
    assert_select ".ec-danger-zone form[action=?][method=post]", profile_path
    assert_select ".ec-danger-zone input[name=confirmation]"
  end

  test "deleting the account wipes the user and everything under it" do
    assert @user.savings.any?, "a fixture precisa ter economias para o teste valer"
    sign_in_as @user

    assert_difference [ "User.count", "Session.count" ], -1 do
      assert_difference "Saving.count", -@user.savings.count do
        assert_difference "Goal.count", -@user.goals.count do
          assert_difference "Category.count", -@user.categories.count do
            delete profile_path, params: { confirmation: @user.email_address }
          end
        end
      end
    end

    assert_redirected_to root_path
    refute User.exists?(@user.id)
  end

  test "the wrong email deletes nothing" do
    sign_in_as @user
    assert_no_difference "User.count" do
      delete profile_path, params: { confirmation: "outro@example.com" }
    end
    assert_redirected_to edit_profile_path
    assert User.exists?(@user.id)
  end

  test "the confirmation ignores case and surrounding spaces" do
    sign_in_as @user
    assert_difference "User.count", -1 do
      delete profile_path, params: { confirmation: "  #{@user.email_address.upcase}  " }
    end
  end

  test "the session ends, so the deleted user is not left signed in" do
    sign_in_as @user
    delete profile_path, params: { confirmation: @user.email_address }
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "signing out is required: a visitor cannot delete anyone" do
    assert_no_difference "User.count" do
      delete profile_path, params: { confirmation: @user.email_address }
    end
    assert_redirected_to new_session_path
  end

  test "the public page explains how to delete without installing the app" do
    get account_deletion_path
    assert_response :success
    assert_select "h1", text: "Como excluir sua conta"
    assert_select "ol li", minimum: 3
    assert_select "meta[name=robots]", count: 0
  end

  test "the public page is listed in the sitemap and linked from the legal pages" do
    get "/sitemap.xml"
    assert_includes response.body, "/excluir-conta"

    get privacy_path
    assert_select ".ec-legal-nav a[href=?]", account_deletion_path
  end
end
