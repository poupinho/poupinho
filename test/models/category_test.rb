require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "name is unique per user, case insensitive" do
    dup = users(:one).categories.new(name: "almoço")
    assert_not dup.valid?

    other = users(:two).categories.new(name: "Almoço")
    assert other.valid?
  end

  test "validates color and icon formats" do
    category = users(:one).categories.new(name: "Teste", color: "verde", icon: "cup")
    assert_not category.valid?
    assert category.errors[:color].any?
    assert category.errors[:icon].any?

    category.color = "#00AA11"
    category.icon = "bi-cup-hot"
    assert category.valid?
    assert_equal "#00aa11", category.color
  end

  test "blank icon falls back to bi-tag" do
    category = users(:one).categories.create!(name: "Sem ícone", icon: "")
    assert_equal "bi-tag", category.icon
  end

  test "destroying a category nullifies its savings" do
    saving = savings(:today_lunch)
    categories(:lunch).destroy
    assert_nil saving.reload.category_id
  end
end
