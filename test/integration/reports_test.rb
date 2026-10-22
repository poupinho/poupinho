require "test_helper"

class ReportsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "renders the current year by default" do
    get reports_path
    assert_response :success
    assert_select "h1", text: "Relatórios"
    assert_select "small", text: /#{Date.current.year}/
    # users(:one) tem economia no ano passado: o ano corrente vai de janeiro ao mês atual.
    assert_select "tbody tr", count: Date.current.month
  end

  test "a user who started this month sees only that month and no monthly chart" do
    user = users(:two)
    user.savings.delete_all
    user.savings.create!(amount: 10, saved_on: Date.current)
    sign_in_as user

    get reports_path
    assert_select "tbody tr", count: 1
    assert_select "tbody td", text: /R\$ 10,00/
    assert_select ".ec-chart-card", count: 1
    assert_select ".ec-section-title", text: "Economizado por mês", count: 0
    assert_select ".ec-section-title", text: "Por categoria no ano"
  end

  test "a year without data shows an empty state" do
    get reports_path(year: 2010)
    assert_select "tbody tr", count: 1
    assert_select "tbody td", text: /Nenhuma economia/
  end

  test "renders a selected year and offers years with data" do
    get reports_path(year: Date.current.year - 1)
    assert_response :success
    assert_select "td", text: /R\$ 100,00/
    assert_select "select[name=year] option", minimum: 2
  end

  test "falls back to the current year on invalid input" do
    get reports_path(year: "abc")
    assert_select "small", text: /#{Date.current.year}/
  end
end
