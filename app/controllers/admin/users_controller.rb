module Admin
  class UsersController < BaseController
    def index
      @count = User.search(params[:q]).count
      @users = User.search(params[:q]).with_savings_stats.order(created_at: :desc).page(params[:page]).per(25)
      @scores = @users.index_with { |user| Gamification::Score.call(user: user) }
    end

    def show
      @user = User.find(params[:id])
      @summary = Dashboards::Summary.call(user: @user)
      @score = Gamification::Score.call(user: @user)
      @goals = Goals::Overview.call(user: @user)
      @recent = @user.savings.includes(:category, :goal).recent.limit(20)
    end
  end
end
