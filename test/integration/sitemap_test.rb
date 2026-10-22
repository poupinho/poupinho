require "test_helper"

class SitemapTest < ActionDispatch::IntegrationTest
  test "sitemap lists the public pages and every tip, on the canonical host" do
    with_env("APP_HOST" => "poupinho.com.br") do
      get "/sitemap.xml"
    end
    assert_response :success
    assert_equal "application/xml", response.media_type

    xml = Nokogiri::XML(response.body)
    xml.remove_namespaces!
    locs = xml.xpath("//url/loc").map(&:text)

    assert_equal "https://poupinho.com.br/", locs.first
    %w[/registration/new /session/new /privacidade /termos /dicas].each do |path|
      assert_includes locs, "https://poupinho.com.br#{path}"
    end
    Tip.all.each { |tip| assert_includes locs, "https://poupinho.com.br/dicas/#{tip.slug}" }
    assert_equal locs.uniq, locs
  end

  test "sitemap keeps the app pages out" do
    get "/sitemap.xml"
    assert_response :success
    %w[/dashboard /savings /goals /categories /reports /profile].each do |path|
      refute_includes response.body, "#{path}<"
    end
  end

  test "robots points to the sitemap and no longer blocks the tips" do
    robots = File.read(Rails.root.join("public/robots.txt"))
    assert_includes robots, "Sitemap: https://poupinho.com.br/sitemap.xml"
    refute_includes robots, "Disallow: /dicas"
    assert_includes robots, "Disallow: /dashboard"
  end
end
