require "test_helper"

class TipTest < ActiveSupport::TestCase
  test "every tip has the fields the public page needs" do
    Tip.all.each do |tip|
      assert tip.slug.present?, "dica sem slug: #{tip.title}"
      assert_match(/\A[a-z0-9-]+\z/, tip.slug, "slug inválido para URL: #{tip.slug}")
      assert tip.description.present?, "dica sem meta description: #{tip.slug}"
      assert tip.body.any?, "dica sem corpo: #{tip.slug}"
      assert tip.steps.size >= 3, "dica com menos de três passos: #{tip.slug}"
    end
  end

  test "slugs are unique across groups" do
    slugs = Tip.all.map(&:slug)
    assert_equal slugs.uniq, slugs
  end

  test "find returns the tip and find! raises on an unknown slug" do
    assert_equal "Café da casa, não da esquina", Tip.find("cafe-da-casa").title
    assert_nil Tip.find("nao-existe")
    assert_raises(ActiveRecord::RecordNotFound) { Tip.find!("nao-existe") }
  end

  test "related brings the rest of the group and never the tip itself" do
    tip = Tip.find("cafe-da-casa")
    assert_equal tip.group.tips.size - 1, tip.related.size
    refute_includes tip.related.map(&:slug), tip.slug
    assert_equal [ tip.group.slug ], tip.related.map { |other| other.group.slug }.uniq
  end

  test "to_param is the slug, so the routes build the pretty url" do
    assert_equal "cafe-da-casa", Tip.find("cafe-da-casa").to_param
  end
end
