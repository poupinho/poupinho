require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  test "summary 'see all' goes to reports and recent 'see all' to the history" do
    sign_in_as users(:one)
    get dashboard_path
    assert_select ".ec-section a[href=?]", reports_path, text: "Ver tudo"
    assert_select ".ec-section a[href=?]", savings_path, text: "Ver tudo"
  end

  test "greeting shows the level chip and the streak tile shows the record" do
    sign_in_as users(:one)
    get dashboard_path
    assert_select ".ec-greeting a.ec-level-chip[href=?]", edit_profile_path, text: /Nível 1.*Iniciante/m
    assert_select ".ec-level-chip .ec-level-bar > span[style*='width: 73%']"
    assert_select ".ec-level-chip-hint", text: "27 pontos para o nível 2"
    assert_select "a.ec-streak-card[href=?] .ec-tile-hint", edit_profile_path, text: "Recorde: 2 dias"
  end

  test "hero goal block is collapsible with a toggle button" do
    sign_in_as users(:one)
    get dashboard_path
    assert_select ".ec-hero-goal[data-controller=expand] button.ec-hero-goal-toggle[aria-expanded=false]"
    assert_select ".ec-hero-goal .ec-hero-goal-head"
    assert_select ".ec-hero-goal #hero-goal-details"
  end

  test "share button opens the share card modal with the three periods and card data" do
    sign_in_as users(:one)
    get dashboard_path
    assert_select ".ec-hero button.ec-hero-share[data-bs-toggle=modal][data-bs-target='#share-card-modal']", text: /Compartilhar/
    assert_select "#share-card-modal[data-controller=share-card][data-action='show.bs.modal->share-card#render']"
    assert_select "#share-card-modal[data-share-card-level-value='Nível 1 · Iniciante']"
    assert_select "#share-card-modal[data-share-card-url-value='poupinho.com.br']"
    assert_select "#share-card-modal[data-share-card-text-value*='%{amount} %{label} com o Poupinho']"
    assert_select "#share-card-modal[data-share-card-text-value*='http://www.example.com/']"
    assert_select "#share-card-modal input[type=radio][data-share-card-target=period]", count: 3
    assert_select "#share-card-modal input#share-period-month[checked][data-amount='R$ 53,30'][data-label=?]",
                  "em #{I18n.l(Date.current, format: '%B').downcase}"
    assert_select "#share-card-modal input#share-period-all[data-amount='R$ 153,30'][data-label='desde que comecei']"
    assert_select "#share-card-modal img[data-share-card-target=preview]"
    assert_select "#share-card-modal button[data-action='share-card#download']", text: /Baixar imagem/
    assert_select "#share-card-modal button[data-share-card-target=share][hidden]", text: /Compartilhar/
  end

  test "share button and modal are hidden while there is nothing saved" do
    sign_in_as users(:two)
    users(:two).savings.delete_all
    get dashboard_path
    assert_select ".ec-hero-share", count: 0
    assert_select "#share-card-modal", count: 0
  end

  setup { sign_in_as users(:one) }

  test "renders hero, KPIs, goal, streak, charts and recent list" do
    get dashboard_path
    assert_response :success
    assert_select ".ec-hero .ec-hero-value", text: "R$ 153,30"
    assert_select ".ec-kpi-card", minimum: 4
    assert_select ".ec-kpi-card", text: /Hoje/
    assert_select ".ec-kpi-card", text: /R\$ 28,30/
    assert_select ".ec-kpi-card", text: /Maior economia.*R\$ 100,00/m
    assert_select ".ec-goal-card", text: /Viagem dos sonhos/
    assert_select ".ec-goal-card", text: /R\$ 100,00/
    assert_select ".ec-goal-card", text: /43%/
    assert_select ".ec-goal-card", text: /Falta R\$ 56,50/
    assert_select ".ec-goal-card a[href=?]", goals_path
    assert_select ".ec-goal-card .ec-hero-progress"
    assert_select ".ec-streak-card", text: /2 dias seguidos/
    assert_select ".ec-dashboard-charts.d-none.d-md-block .ec-chart-card", minimum: 3
    assert_select ".ec-recent-item", text: /Levei marmita/
    assert_select ".ec-recent-item", text: /Hoje/
  end

  test "quick add form creates a saving and returns to dashboard" do
    assert_difference("users(:one).savings.count", 1) do
      post savings_path, params: { return_to: dashboard_path,
                                   saving: { description: "Pulei o lanche", amount: "7.50", saved_on: Date.current,
                                             category_id: categories(:lunch).id } }
    end
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select ".ec-toast-success", text: /R\$ 7,50/
  end

  test "invalid data with return_to re-renders the form keeping the destination" do
    assert_no_difference("Saving.count") do
      post savings_path, params: { return_to: dashboard_path, saving: { description: "", amount: "0", saved_on: Date.current } }
    end
    assert_response :unprocessable_content
    assert_select ".alert-danger"
    assert_select "input[name=return_to][value=?]", dashboard_path
  end

  test "new saving form from the dashboard carries return_to" do
    get new_saving_path(return_to: dashboard_path)
    assert_select "input[name=return_to][value=?]", dashboard_path
    assert_select "a.ec-back[href=?]", dashboard_path

    get new_saving_path(return_to: "https://evil.example.com")
    assert_select "input[name=return_to]", count: 0
  end

  test "return_to only accepts same-origin urls" do
    post savings_path, params: { return_to: "https://evil.example.com", saving: { description: "x", amount: "1", saved_on: Date.current } }
    assert_redirected_to savings_path
  end

  test "hero falls back to the monthly goal when the user has no goals" do
    users(:one).goals.destroy_all
    get dashboard_path
    assert_select ".ec-goal-card", text: /Meta de/
    assert_select ".ec-goal-card", text: /R\$ 200,00/
    assert_select ".ec-goal-card", text: /Viagem dos sonhos/, count: 0
  end

  test "hero announces an achieved goal" do
    goals(:trip).update!(target_amount: 10)
    get dashboard_path
    assert_select ".ec-goal-card", text: /Meta atingida/
  end

  test "suggests creating a goal when there is none and no monthly goal" do
    user = users(:two)
    user.goals.destroy_all
    sign_in_as user
    get dashboard_path
    assert_select ".ec-goal-card", text: /Crie uma meta/
    assert_select ".ec-goal-card a[href=?]", new_goal_path
  end
end
