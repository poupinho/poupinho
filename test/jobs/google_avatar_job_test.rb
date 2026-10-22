require "test_helper"

class GoogleAvatarJobTest < ActiveJob::TestCase
  setup { @user = users(:two) }

  test "downloads the photo in a larger size and attaches it" do
    requested = nil
    bytes = file_fixture("avatar.jpg").binread
    stubbing(Avatars::Download, :call, ->(url) { requested = url; { io: StringIO.new(bytes), content_type: "image/jpeg" } }) do
      GoogleAvatarJob.perform_now(@user, "https://lh3.googleusercontent.com/a/abc=s96-c")
    end
    assert_equal "https://lh3.googleusercontent.com/a/abc=s256-c", requested
    assert @user.reload.avatar.attached?
    assert_equal "google.jpeg", @user.avatar.filename.to_s
    assert_equal "image/jpeg", @user.avatar.content_type
  end

  test "keeps an existing avatar and ignores failed downloads" do
    @user.avatar.attach(io: file_fixture("avatar.png").open, filename: "mine.png", content_type: "image/png")
    stubbing(Avatars::Download, :call, ->(_url) { flunk "should not download" }) do
      GoogleAvatarJob.perform_now(@user, "https://lh3.googleusercontent.com/a/abc=s96-c")
    end
    assert_equal "mine.png", @user.reload.avatar.filename.to_s

    stubbing(Avatars::Download, :call, ->(_url) { nil }) do
      GoogleAvatarJob.perform_now(users(:one), "https://lh3.googleusercontent.com/a/abc=s96-c")
    end
    assert_not users(:one).reload.avatar.attached?
  end
end
