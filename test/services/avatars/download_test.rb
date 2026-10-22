require "test_helper"

class Avatars::DownloadTest < ActiveSupport::TestCase
  test "returns the image when the response is a small image" do
    with_response(ok("image/jpeg", "JPEGDATA")) do
      result = Avatars::Download.call("https://lh3.googleusercontent.com/a/x=s256-c")
      assert_equal "image/jpeg", result[:content_type]
      assert_equal "JPEGDATA", result[:io].read
    end
  end

  test "strips charset parameters from the content type" do
    with_response(ok("image/png; charset=binary", "PNG")) do
      assert_equal "image/png", Avatars::Download.call("https://example.com/a.png")[:content_type]
    end
  end

  test "rejects non-image responses, huge files, http urls and failures" do
    with_response(ok("text/html", "<html>")) { assert_nil Avatars::Download.call("https://example.com/a") }
    with_response(ok("image/png", "x" * (User::AVATAR_MAX_BYTES + 1))) { assert_nil Avatars::Download.call("https://example.com/a") }
    with_response(ok("image/png", "PNG")) { assert_nil Avatars::Download.call("http://example.com/a.png") }
    with_response(Net::HTTPNotFound.new("1.1", "404", "Not Found")) { assert_nil Avatars::Download.call("https://example.com/a") }
    with_response(->(_uri) { raise SocketError, "down" }) { assert_nil Avatars::Download.call("https://example.com/a") }
    assert_nil Avatars::Download.call("not a url")
  end

  test "follows redirects up to a limit" do
    hops = []
    responder = ->(uri) {
      hops << uri.to_s
      hops.size < 3 ? redirect("https://example.com/#{hops.size}") : ok("image/webp", "WEBP")
    }
    with_response(responder) do
      assert_equal "image/webp", Avatars::Download.call("https://example.com/0")[:content_type]
    end
    assert_equal %w[https://example.com/0 https://example.com/1 https://example.com/2], hops

    with_response(->(uri) { redirect(uri.to_s + "x") }) { assert_nil Avatars::Download.call("https://example.com/loop") }
  end

  private

  def ok(content_type, body)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response["content-type"] = content_type
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  def redirect(location)
    response = Net::HTTPFound.new("1.1", "302", "Found")
    response["location"] = location
    response
  end

  def with_response(response, &block)
    impl = response.respond_to?(:call) ? response : ->(_uri) { response }
    Avatars::Download.class_eval { alias_method :__original_get, :get; define_method(:get) { |uri| impl.call(uri) } }
    yield
  ensure
    Avatars::Download.class_eval { alias_method :get, :__original_get; remove_method :__original_get }
  end
end
