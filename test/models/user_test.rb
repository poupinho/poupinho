require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "creates default categories after sign up" do
    user = User.create!(email_address: "novo@example.com", phone: "11912345678", password: "password", password_confirmation: "password")
    assert_equal User::DEFAULT_CATEGORIES.size, user.categories.count
    assert_equal User::DEFAULT_CATEGORIES.map { |c| c[:name] }, user.categories.map(&:name)
  end

  test "normalizes email and validates format" do
    user = User.new(email_address: "  Foo@Example.COM ", phone: "11912345678", password: "password")
    assert user.valid?
    assert_equal "foo@example.com", user.email_address

    user.email_address = "invalido"
    assert_not user.valid?
  end

  test "requires unique email" do
    user = User.new(email_address: users(:one).email_address, password: "password")
    assert_not user.valid?
    assert user.errors[:email_address].any?
  end

  test "password must have at least 6 chars" do
    user = User.new(email_address: "x@example.com", password: "123")
    assert_not user.valid?
  end

  test "display_name falls back to email and first_name uses first word" do
    assert_equal "Ana", users(:one).display_name
    assert_equal "Ana", users(:one).first_name
    user = User.new(email_address: "carlos@example.com")
    assert_equal "carlos@example.com", user.display_name
    assert_equal "carlos", user.first_name
  end

  test "phone is required on create, must be a mobile with area code and is normalized to digits" do
    user = User.new(email_address: "p@example.com", password: "segredo1")
    assert_not user.valid?
    assert user.errors[:phone].any?

    user.phone = "(11) 1234-5678" # fixo, sem o 9
    assert_not user.valid?
    assert user.errors[:phone].any?

    user.phone = "(11) 91234-5678"
    assert user.valid?
    assert_equal "11912345678", user.phone
    assert_equal "(11) 91234-5678", user.formatted_phone

    # Contas antigas sem celular continuam válidas ao editar.
    assert users(:one).update(phone: nil)
  end

  test "monthly goal must be positive when present" do
    user = users(:one)
    user.monthly_goal = 0
    assert_not user.valid?
    user.monthly_goal = nil
    assert user.valid?
  end
end
