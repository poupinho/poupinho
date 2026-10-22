class DashboardController < ApplicationController
  def index
    @summary = Dashboards::Summary.call(user: current_user)
    # Meta em destaque (a de menor ordem); sem metas, o card cai na meta mensal do perfil.
    @featured_goal = Goals::Overview.call(user: current_user).first
    @saving = current_user.savings.new(saved_on: Date.current)
    @categories = current_user.categories
    @score = Gamification::Score.call(user: current_user)
  end
end
