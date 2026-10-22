class SavingsController < ApplicationController
  before_action :set_saving, only: %i[ show edit update destroy ]
  before_action :load_form_options, only: %i[ index new create edit update ]
  before_action :set_return_to, only: %i[ new create ]

  def index
    scope = current_user.savings.includes(:category).search(params[:q])
    scope = scope.on_month(@month) if @month = parse_month(params[:month])
    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

    @total = scope.sum(:amount).to_d
    @count = scope.count
    @savings = scope.recent.page(params[:page])

    # Rolagem infinita: a sentinela (Turbo Frame) pede só a próxima página.
    render partial: "savings/page", locals: { savings: @savings }, layout: false if turbo_frame_request?
  end

  def show
  end

  def new
    # A meta em destaque (menor posição) já vem selecionada; dá para trocar ou tirar no formulário.
    @saving = current_user.savings.new(saved_on: Date.current, goal: @goals.first)
  end

  def create
    @saving = current_user.savings.new(saving_params)
    before = Gamification::Score.call(user: current_user)

    if @saving.save
      after = Gamification::Score.call(user: current_user)
      earned = after.points - before.points
      flash[:notice] = t("savings.flash.created", amount: helpers.format_brl(@saving.amount),
                                                  points: t("gamification.earned", count: earned))
      # Subiu de nível: toast especial com confete (layouts/_toasts).
      flash[:level_up] = { "level" => after.level, "name" => after.level_name } if after.level > before.level
      redirect_to return_to_or(savings_path)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @saving.update(saving_params)
      redirect_to saving_path(@saving), notice: t("savings.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @saving.destroy
    redirect_to savings_path, notice: t("savings.flash.destroyed"), status: :see_other
  end

  private

  def set_saving
    @saving = current_user.savings.find(params[:id])
  end

  def load_form_options
    @categories = current_user.categories
    @goals = current_user.goals
  end

  # Destino após salvar (ex.: voltar ao dashboard); só aceita URLs da própria app.
  def set_return_to
    @return_to = url_from(params[:return_to])
  end

  def saving_params
    params.require(:saving).permit(:amount, :description, :saved_on, :category_id, :goal_id)
  end

  def parse_month(value)
    return nil if value.blank?
    Date.strptime(value, "%Y-%m")
  rescue ArgumentError
    nil
  end

  def return_to_or(fallback)
    @return_to || fallback
  end
end
