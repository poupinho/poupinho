require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "landing page renders hero, quotes, simulator and examples table" do
    get root_path
    assert_response :success
    assert_select "header.ec-topbar", count: 0
    assert_select "nav.ec-bottom-nav", count: 0
    assert_select ".ec-landing-hero h1", text: /Sua economia de hoje é o seu futuro de amanhã/
    assert_select ".ec-landing-quote", minimum: 3
    assert_select "title", text: "Poupinho — Sua economia de hoje é o seu futuro de amanhã"
    assert_select "meta[name=description][content*='deixou de gastar']"
    assert_select "meta[property='og:title'][content*='Poupinho']"
    assert_select "meta[property='og:image'][content=?]", "http://www.example.com/og-image.png"
    assert_select "meta[property='og:image:width'][content='1200']"
    assert_select "meta[name='twitter:card'][content='summary_large_image']"
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/"
    assert_select "meta[name=robots]", count: 0
    assert_select "script[type='application/ld+json']", text: /WebApplication/
    assert_select ".ec-demo[data-controller=demo] .ec-demo-step", count: 3
    assert_select ".ec-landing-hero-grid[data-controller=slides] .ec-landing-mock-slide", count: 4
    assert_select ".ec-landing-hero-copy-slide", count: 4
    assert_select ".ec-landing-hero-copy-slide h1", count: 1
    assert_select ".ec-landing-mock-tab", count: 4
    assert_select ".ec-demo input[data-demo-target=amount][value='12,00']"
    assert_select ".ec-landing-testimonials[data-controller~=carousel]"
    assert_select ".ec-landing-testimonial", count: 6
    assert_select ".ec-landing-testimonial figcaption strong", text: "Mariana S."
    assert_select "[data-controller='simulator']"
    assert_select "[data-simulator-target='saved']", count: 4
    assert_select ".ec-landing-table tbody tr", count: 4
    assert_select ".ec-landing-table tbody", text: /R\$ 3\.650/
    assert_select "a[href='#{new_registration_path}']", minimum: 2
    assert_select "a[href='#{new_session_path}']", minimum: 1
  end

  test "authenticated user sees the landing with shortcuts to the app instead of a redirect" do
    sign_in_as users(:one)
    get root_path
    assert_response :success
    assert_select ".ec-landing-hero h1"
    assert_select "header.ec-topbar", count: 0
    assert_select "nav.ec-bottom-nav", count: 0
    assert_select ".ec-landing-actions a[href=?]", dashboard_path
    assert_select ".ec-landing-cta a[href=?]", dashboard_path
    assert_select "a[href='#{new_registration_path}']", count: 0
    assert_select "a[href='#{new_session_path}']", count: 0
  end
end

class HomeParallaxTest < ActionDispatch::IntegrationTest
  test "landing has parallax layers, tilt card and reveal elements" do
    get root_path
    assert_select ".ec-landing[data-controller='parallax']"
    assert_select "[data-parallax-section]", minimum: 3
    assert_select "[data-parallax-target='layer'][data-parallax-speed]", minimum: 8
    assert_select ".ec-landing-mock[data-parallax-target='tilt']", count: 1
    assert_select ".ec-landing-chip", count: 3
    assert_select ".ec-reveal[data-parallax-target='reveal']", minimum: 10
  end
end
