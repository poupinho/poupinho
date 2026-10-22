class GoalsController < ApplicationController
  before_action :set_goal, only: %i[ edit update destroy ]

  def index
    @rows = Goals::Overview.call(user: current_user)
    @featured = @rows.first
    @others = @rows.drop(1)
  end

  def new
    @goal = current_user.goals.new(position: current_user.goals.count)
    @onboarding = onboarding?
  end

  def create
    @goal = current_user.goals.new(goal_params)
    @onboarding = onboarding?

    if @goal.save
      if @onboarding
        redirect_to dashboard_path, notice: t("goals.flash.created_onboarding")
      else
        redirect_to goals_path, notice: t("goals.flash.created")
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @goal.update(goal_params)
      redirect_to goals_path, notice: t("goals.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @goal.destroy
    redirect_to goals_path, notice: t("goals.flash.destroyed"), status: :see_other
  end

  private

  # Vindo do cadastro (new_goal_path(onboarding: 1)): cabeçalho de boas-vindas e volta ao dashboard.
  def onboarding?
    params[:onboarding].present?
  end

  def set_goal
    @goal = current_user.goals.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:name, :icon, :color, :target_amount, :deadline, :position)
  end
end
