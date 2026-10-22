require "test_helper"

class GoalsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index highlights the first goal and lists the others" do
    get goals_path
    assert_response :success
    assert_select ".ec-goal-featured h2", text: /Viagem dos sonhos/
    assert_select ".ec-goal-featured .ec-goal-amounts strong", text: "R$ 43,50"
    assert_select ".ec-goal-featured .ec-goal-pct", text: "43%"
    assert_select ".ec-goal-featured .ec-goal-meta", text: /Falta R\$ 56,50/
    assert_select ".ec-goal-featured .ec-goal-meta", text: /Prazo/
    assert_select ".ec-goal-row", count: 1
    assert_select ".ec-goal-row", text: /Reserva de emergência/
    assert_select ".ec-goal-row", text: /Notebook novo/, count: 0
    assert_select ".ec-tip[data-controller='dismissible']"
  end

  test "index shows an empty state without goals" do
    users(:one).goals.destroy_all
    get goals_path
    assert_select ".ec-goal-featured", count: 0
    assert_select ".ec-empty", text: /Nenhuma meta ainda/
  end

  test "achieved goal is announced" do
    goals(:trip).update!(target_amount: 10)
    get goals_path
    assert_select ".ec-goal-featured .ec-goal-meta", text: /Meta atingida/
  end

  test "create, update and destroy" do
    assert_difference("users(:one).goals.count", 1) do
      post goals_path, params: { goal: { name: "Notebook", target_amount: "2500.00", icon: "bi-laptop",
                                         color: "#8b5cf6", deadline: Date.current + 30, position: 2 } }
    end
    assert_redirected_to goals_path
    goal = users(:one).goals.find_by(name: "Notebook")

    patch goal_path(goal), params: { goal: { name: "Notebook novo" } }
    assert_redirected_to goals_path
    assert_equal "Notebook novo", goal.reload.name

    assert_difference("Goal.count", -1) { delete goal_path(goal) }
    assert_redirected_to goals_path
  end

  test "creating the first goal during onboarding goes to the dashboard" do
    post goals_path, params: { onboarding: 1, goal: { name: "Reserva", target_amount: "1000.00", icon: "bi-shield-check", color: "#3b82f6" } }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select ".alert, .toast, [role=status], .ec-toast", text: /Meta criada/, minimum: 0
    assert users(:one).goals.exists?(name: "Reserva")
  end

  test "invalid create renders the form again" do
    assert_no_difference("Goal.count") do
      post goals_path, params: { goal: { name: "", target_amount: "0" } }
    end
    assert_response :unprocessable_content
    assert_select ".alert-danger li", minimum: 1
  end

  test "edit form shows the target formatted in BRL" do
    get edit_goal_path(goals(:trip))
    assert_select "input[name='goal[target_amount]'][value='100,00']"
  end

  test "cannot touch another user's goal" do
    get edit_goal_path(goals(:other_user_goal))
    assert_response :not_found
  end

  test "saving form offers the user's goals" do
    get new_saving_path
    assert_select "select[name='saving[goal_id]'] option", text: "Viagem dos sonhos"
    assert_select "select[name='saving[goal_id]'] option", text: "Notebook novo", count: 0
  end

  test "a saving can be linked to a goal" do
    post savings_path, params: { saving: { description: "Guardei para a viagem", amount: "30.00",
                                           saved_on: Date.current, goal_id: goals(:trip).id } }
    saving = Saving.order(:created_at).last
    assert_equal goals(:trip), saving.goal

    get goals_path
    assert_select ".ec-goal-featured .ec-goal-amounts strong", text: "R$ 73,50"
  end
end
