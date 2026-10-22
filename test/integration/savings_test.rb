require "test_helper"

class SavingsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index lists only the current user's savings with totals" do
    get savings_path
    assert_response :success
    assert_select ".ec-saving-row", text: /Levei marmita/
    assert_select ".ec-saving-row", text: /Do outro usuário/, count: 0
    assert_select ".ec-list-summary", text: /R\$ 153,30/
  end

  test "index filters by month, category and search" do
    get savings_path(month: Date.current.strftime("%Y-%m"))
    assert_select ".ec-saving-row", text: /Economia do ano passado/, count: 0

    get savings_path(category_id: categories(:transport).id)
    assert_select ".ec-saving-row", text: /Fui de bicicleta/
    assert_select ".ec-saving-row", text: /Levei marmita/, count: 0

    get savings_path(q: "bicicleta")
    assert_select ".ec-list-summary", text: /1 registro/

    get savings_path(month: "invalido")
    assert_response :success
  end

  test "index paginates with a lazy frame and appends the next page as a turbo stream" do
    user = users(:one)
    30.times { |i| user.savings.create!(amount: 1, description: "Item #{i}", saved_on: Date.current - i) }

    get savings_path(q: "Item")
    assert_response :success
    assert_select "ul#savings_items .ec-saving-row", count: 25
    assert_select "turbo-frame#savings_page_2[src=?][loading=lazy]", savings_path(q: "Item", page: 2)

    get savings_path(q: "Item", page: 2), headers: { "Turbo-Frame" => "savings_page_2" }
    assert_response :success
    assert_select "turbo-frame#savings_page_2 turbo-stream[action=append][target=savings_items]"
    assert_select "turbo-frame#savings_page_2 turbo-stream template .ec-saving-row", count: 5
    assert_select "turbo-frame#savings_page_3", count: 0
    assert_select "header.ec-topbar", count: 0
  end

  test "filters collapse on mobile and open when a filter is active" do
    get savings_path
    assert_select "form#savings-filters.collapse:not(.show)"
    assert_select ".ec-filters-toggle[aria-expanded=false]"

    get savings_path(q: "bicicleta")
    assert_select "form#savings-filters.collapse.show"
    assert_select ".ec-filters-toggle .badge", text: "1"
  end

  test "create reports the points earned" do
    post savings_path, params: { saving: { description: "Marmita", amount: "25.00", saved_on: Date.current } }
    assert_redirected_to savings_path
    # +10 pela economia, +2 pelo valor (25 / 10). Sem novo nível: 73 -> 85 pontos.
    assert_equal "Economia de R$ 25,00 registrada! +12 pontos", flash[:notice]
    assert_nil flash[:level_up]
  end

  test "crossing a level threshold shows the level-up toast with confetti" do
    # users(:one) tem 73 pontos; R$ 1.000 rende +10 +100 = 110 -> 183 pontos, nível 2.
    post savings_path, params: { saving: { description: "Bônus", amount: "1000.00", saved_on: Date.current } }
    assert_equal({ "level" => 2, "name" => "Aprendiz" }, flash[:level_up])
    follow_redirect!
    assert_select ".ec-toast-level-up[data-controller=celebrate][data-duration='8000']", text: /Você subiu para o nível 2: Aprendiz/
    assert_select ".ec-toast-success", text: /\+110 pontos/
  end

  test "create, show, update and destroy" do
    assert_difference("Saving.count", 1) do
      post savings_path, params: { saving: { description: "Nova", amount: "12.34", saved_on: Date.current } }
    end
    saving = Saving.order(:created_at).last
    assert_redirected_to savings_path

    get saving_path(saving)
    assert_response :success
    assert_select "h2", text: "Nova"

    patch saving_path(saving), params: { saving: { description: "Editada" } }
    assert_redirected_to saving_path(saving)
    assert_equal "Editada", saving.reload.description

    assert_difference("Saving.count", -1) do
      delete saving_path(saving)
    end
    assert_redirected_to savings_path
  end

  test "invalid create renders the form again" do
    post savings_path, params: { saving: { description: "", amount: "", saved_on: "" } }
    assert_response :unprocessable_content
    assert_select ".alert-danger"
  end

  test "cannot access another user's saving" do
    get saving_path(savings(:other_user))
    assert_response :not_found
  end

  test "edit form shows amount formatted in BRL and the category chip selected" do
    get edit_saving_path(savings(:today_lunch))
    assert_select "input[name='saving[amount]'][value='18,50']"
    assert_select ".ec-chip input[type=radio][value=?][checked]", categories(:lunch).id.to_s
    assert_select ".ec-chip input[type=radio][value=''][checked]", count: 0
  end

  test "new form preselects the featured goal" do
    get new_saving_path
    first_goal = users(:one).goals.first
    assert_select "select[name='saving[goal_id]'] option[selected][value=?]", first_goal.id.to_s
  end

  test "new form preselects no category" do
    get new_saving_path
    assert_select ".ec-chip input[type=radio]", minimum: 2
    assert_select ".ec-chip input[type=radio][value=''][checked]"
  end
end
