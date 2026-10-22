class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ edit update destroy ]

  def index
    @categories = current_user.categories.ordered
    @counts = current_user.savings.group(:category_id).count
    @totals = current_user.savings.group(:category_id).sum(:amount)
  end

  def new
    @category = current_user.categories.new(position: current_user.categories.count)
  end

  def create
    @category = current_user.categories.new(category_params)

    if @category.save
      redirect_to categories_path, notice: t("categories.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: t("categories.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path, notice: t("categories.flash.destroyed"), status: :see_other
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color, :position)
  end
end
