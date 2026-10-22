require "test_helper"

class CategoriesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index lists the user's categories with totals" do
    get categories_path
    assert_response :success
    assert_select ".ec-category-card", count: 2
    assert_select ".ec-category-card", text: /Almoço/
    assert_select ".ec-category-card", text: /R\$ 43,50/
    assert_select ".ec-category-card", text: /Café/, count: 0
  end

  test "create, update and destroy" do
    assert_difference("users(:one).categories.count", 1) do
      post categories_path, params: { category: { name: "Livros", icon: "bi-book", color: "#123456" } }
    end
    category = users(:one).categories.find_by!(name: "Livros")

    patch category_path(category), params: { category: { name: "Leitura" } }
    assert_redirected_to categories_path
    assert_equal "Leitura", category.reload.name

    assert_difference("Category.count", -1) { delete category_path(category) }
  end

  test "invalid create renders errors" do
    post categories_path, params: { category: { name: "Almoço" } }
    assert_response :unprocessable_content
    assert_select ".alert-danger"
  end

  test "cannot edit another user's category" do
    get edit_category_path(categories(:other_user_category))
    assert_response :not_found
  end
end
