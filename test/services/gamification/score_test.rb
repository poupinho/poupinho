require "test_helper"

module Gamification
  class ScoreTest < ActiveSupport::TestCase
    # users(:one): 4 economias (18,50 / 9,80 / 25,00 / 100,00), sequência atual de 2 dias,
    # uma economia isolada no ano passado, meta "Viagem" (alvo 100) com 43,50 guardados.
    test "sums points from savings, amounts and the first-saving bonus" do
      score = Score.call(user: users(:one))
      assert_equal 40, score.breakdown[:savings]      # 4 × 10
      assert_equal 13, score.breakdown[:amount]       # 1 + 0 + 2 + 10
      assert_equal 20, score.breakdown[:first_saving]
      assert_equal 0, score.breakdown[:streaks]       # maior sequência tem 2 dias
      assert_equal 0, score.breakdown[:goals]
      assert_equal 73, score.points
      assert_equal 2, score.best_streak
    end

    test "level, progress and points to next level" do
      score = Score.call(user: users(:one))
      assert_equal 1, score.level
      assert_equal "Iniciante", score.level_name
      assert_equal 0, score.level_floor
      assert_equal 100, score.next_level_points
      assert_equal 27, score.points_to_next
      assert_equal 73, score.progress_pct
      assert_not score.max_level?
    end

    test "amount points are capped at 100 per saving" do
      user = users(:two)
      user.savings.delete_all
      user.savings.create!(amount: 5_000, saved_on: Date.current)
      score = Score.call(user: user)
      assert_equal 100, score.breakdown[:amount]
      assert_equal 10 + 100 + 20, score.points
    end

    test "streak milestones count once per run, for every milestone crossed" do
      user = users(:two)
      user.savings.delete_all
      # Run de 8 dias (cruza 3 e 7), um buraco, run de 3 dias (cruza 3).
      8.times { |i| user.savings.create!(amount: 1, saved_on: Date.current - 20 + i) }
      3.times { |i| user.savings.create!(amount: 1, saved_on: Date.current - 5 + i) }
      score = Score.call(user: user)
      assert_equal 15 + 50 + 15, score.breakdown[:streaks]
      assert_equal 8, score.best_streak
    end

    test "achieved goals earn a bonus" do
      user = users(:one)
      user.savings.create!(amount: 60, saved_on: Date.current, goal: goals(:trip)) # 43,50 + 60 >= 100
      score = Score.call(user: user)
      assert_equal 150, score.breakdown[:goals]
    end

    test "level thresholds and the last level" do
      floors = Score::LEVELS.to_h
      assert_equal 100, floors[2]
      assert_equal 6_000, floors[7]

      user = users(:two)
      user.savings.delete_all
      # 60 economias de R$ 1.000 = 60 × (10 + 100) + 20 = 6.620 pontos (sem sequência: dias alternados).
      60.times { |i| user.savings.create!(amount: 1_000, saved_on: Date.current - i * 2) }
      score = Score.call(user: user)
      assert_equal 6_620, score.points
      assert_equal 7, score.level
      assert score.max_level?
      assert_nil score.next_level_points
      assert_equal 0, score.points_to_next
      assert_equal 100, score.progress_pct
    end

    test "a user without savings starts at level 1 with zero points" do
      user = users(:two)
      user.savings.delete_all
      score = Score.call(user: user)
      assert_equal 0, score.points
      assert_equal 1, score.level
      assert_equal 0, score.progress_pct
      assert_equal 0, score.best_streak
    end
  end
end
