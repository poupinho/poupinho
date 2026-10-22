require "test_helper"

class SavingTest < ActiveSupport::TestCase
  test "valid with amount, description and date" do
    saving = users(:one).savings.new(amount: 10, description: "Teste", saved_on: Date.current)
    assert saving.valid?
  end

  test "amount must be positive" do
    saving = users(:one).savings.new(amount: 0, description: "Teste", saved_on: Date.current)
    assert_not saving.valid?
    assert saving.errors[:amount].any?
  end

  test "description is optional and normalized" do
    saving = users(:one).savings.new(amount: 10, description: "  ", saved_on: Date.current)
    assert saving.valid?
    assert_nil saving.description

    saving.description = "  muitos    espaços  "
    assert saving.valid?
    assert_equal "muitos espaços", saving.description
  end

  test "title falls back to the category name and then to a generic label" do
    saving = users(:one).savings.new(amount: 10, saved_on: Date.current, category: categories(:lunch))
    assert_equal categories(:lunch).name, saving.title

    saving.category = nil
    assert_equal "Economia", saving.title

    saving.description = "Marmita"
    assert_equal "Marmita", saving.title
  end

  test "saved_on cannot be in the future" do
    saving = users(:one).savings.new(amount: 10, description: "Teste", saved_on: Date.current + 1)
    assert_not saving.valid?
    assert saving.errors[:saved_on].any?
  end

  test "category must belong to the same user" do
    saving = users(:one).savings.new(amount: 10, description: "Teste", saved_on: Date.current,
                                     category: categories(:other_user_category))
    assert_not saving.valid?
    assert saving.errors[:category].any?
  end

  test "scopes filter by month, year and search" do
    user = users(:one)
    assert_includes user.savings.on_month(Date.current), savings(:today_lunch)
    assert_not_includes user.savings.on_month(Date.current), savings(:last_year)
    assert_equal [ savings(:last_year) ], user.savings.on_year(Date.current.year - 1).to_a
    assert_equal [ savings(:today_lunch) ], user.savings.search("MARMITA").to_a
    assert_equal user.savings.count, user.savings.search("").count
  end
end
