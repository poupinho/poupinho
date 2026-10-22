class ProfilesController < ApplicationController
  before_action :set_user

  def edit
    @score = Gamification::Score.call(user: current_user)
  end

  def update
    attrs = profile_params
    attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
    remove_avatar = attrs.delete(:remove_avatar) == "1" && attrs[:avatar].blank?

    if @user.update(attrs)
      @user.avatar.purge_later if remove_avatar
      redirect_to dashboard_path, notice: t("profiles.flash.updated")
    else
      @score = Gamification::Score.call(user: current_user)
      render :edit, status: :unprocessable_content
    end
  end

  # A Play exige que quem cria conta no app consiga apagá-la, com os dados junto.
  # Pedimos o e-mail digitado porque contas criadas pelo Google não têm senha que
  # o usuário conheça, então confirmar por senha deixaria essas contas de fora.
  def destroy
    if params[:confirmation].to_s.strip.downcase == @user.email_address
      @user.destroy!
      cookies.delete(:session_id)
      redirect_to root_path, notice: t("profiles.delete.done")
    else
      redirect_to edit_profile_path, alert: t("profiles.delete.mismatch")
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:name, :email_address, :phone, :monthly_goal, :password, :password_confirmation,
                                 :avatar, :remove_avatar)
  end
end
