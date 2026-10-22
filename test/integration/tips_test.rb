require "test_helper"

class TipsTest < ActionDispatch::IntegrationTest
  test "index is public and indexable" do
    get tips_path
    assert_response :success
    assert_select "h1", text: "Dicas para poupar"
    assert_select "meta[name=?][content*=?]", "description", "dicas práticas"
    assert_select "meta[name=robots]", count: 0
    assert_select "link[rel=canonical]"
  end

  test "index lists every tip grouped by theme, each linking to its own page" do
    get tips_path
    assert_select ".ec-tips-group", count: 4
    assert_select ".ec-tip-card", count: 15
    assert_select ".ec-tip-card h3 a[href=?]", tip_path("marmita-dois-dias-por-semana"),
                  text: "Marmita dois dias por semana"
    Tip.all.each { |tip| assert_select "a[href=?]", tip_path(tip) }
  end

  test "index sends the visitor to sign up and the member to a new saving" do
    get tips_path
    assert_select ".ec-tips-cta a[href=?]", new_registration_path

    sign_in_as users(:one)
    get tips_path
    assert_select ".ec-tips-cta a[href=?]", new_saving_path
  end

  test "tip page is public and shows the full content" do
    get tip_path("cafe-da-casa")
    assert_response :success
    assert_select "h1", text: "Café da casa, não da esquina"
    assert_select ".ec-tip-steps li", minimum: 3
    assert_select ".ec-tip-math p"
    assert_select ".ec-tip-breadcrumb a[href=?]", tips_path
    assert_select "meta[name=robots]", count: 0
  end

  test "tip page links to the other tips of the same group" do
    get tip_path("cafe-da-casa")
    assert_select ".ec-tip-related a[href=?]", tip_path("marmita-dois-dias-por-semana")
    assert_select ".ec-tip-related a[href=?]", tip_path("cafe-da-casa"), count: 0
    assert_select ".ec-tip-related a[href=?]", tip_path("trajetos-curtos-a-pe"), count: 0
  end

  test "tip page carries structured data for search engines" do
    get tip_path("cafe-da-casa")
    json = JSON.parse(css_select("script[type='application/ld+json']").first.text)
    types = json["@graph"].map { |node| node["@type"] }
    assert_includes types, "Article"
    assert_includes types, "BreadcrumbList"
  end

  test "unknown slug is a 404" do
    get tip_path("dica-que-nao-existe")
    assert_response :not_found
  end

  test "signed in members keep the app frame" do
    sign_in_as users(:one)
    get tip_path("cafe-da-casa")
    assert_response :success
    assert_select ".ec-public", count: 0
    assert_select ".ec-tips-cta a[href=?]", new_saving_path
  end

  test "the landing links to the tips, so search engines reach them from the home" do
    get root_path
    assert_select ".ec-landing-footer-links a[href=?]", tips_path
    assert_select ".ec-landing-links a[href=?]", tips_path
  end

  test "dashboard and goals tip cards link to the tips page" do
    sign_in_as users(:one)
    get dashboard_path
    assert_select ".ec-tip a.ec-tip-link[href=?]", tips_path

    get goals_path
    assert_select ".ec-tip a.ec-tip-link[href=?]", tips_path
  end
end
