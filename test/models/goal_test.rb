require "test_helper"

class GoalTest < ActiveSupport::TestCase
  test "requires name, target amount, icon and color" do
    goal = users(:one).goals.new
    assert_not goal.valid?
    assert goal.errors.of_kind?(:name, :blank)
    assert goal.errors.of_kind?(:target_amount, :blank)
  end

  test "name is unique per user, case insensitive" do
    duplicate = users(:one).goals.new(name: "viagem dos sonhos", target_amount: 10)
    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)

    assert users(:two).goals.new(name: "Viagem dos sonhos", target_amount: 10).valid?
  end

  test "target amount must be positive" do
    goal = users(:one).goals.new(name: "Nova", target_amount: 0)
    assert_not goal.valid?
    assert_includes goal.errors[:target_amount].to_sentence, "maior que 0"
  end

  test "icon must look like a bootstrap icon and color must be a hex code" do
    goal = users(:one).goals.new(name: "Nova", target_amount: 10, icon: "airplane", color: "verde")
    assert_not goal.valid?
    assert_includes goal.errors[:icon].to_sentence, "Bootstrap Icons"
    assert_includes goal.errors[:color].to_sentence, "#RRGGBB"
  end

  test "defaults fill icon and color" do
    goal = users(:one).goals.create!(name: "Sem enfeite", target_amount: 50)
    assert_equal "bi-bullseye", goal.icon
    assert_equal "#0ba360", goal.color
  end

  test "destroying a goal keeps its savings without a goal" do
    saving = savings(:today_lunch)
    assert_equal goals(:trip), saving.goal

    assert_no_difference("Saving.count") { goals(:trip).destroy }
    assert_nil saving.reload.goal_id
  end

  test "a saving cannot point to another user's goal" do
    saving = users(:one).savings.new(description: "Teste", amount: 5, saved_on: Date.current,
                                     goal: goals(:other_user_goal))
    assert_not saving.valid?
    assert saving.errors.of_kind?(:goal, :invalid)
  end
end
