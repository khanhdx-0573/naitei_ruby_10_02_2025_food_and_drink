class SessionsController < ApplicationController
  def new; end

  def create
    email = params.dig(:session, :email)
    password = params.dig(:session, :password)
    @user = User.find_by(email:)
    if @user&.authenticate(password)
      log_in @user
      redirect_to root_path
    else
      flash.now[:danger] = t "login.not_valid_account"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    return unless user_signed_in?

    log_out
    redirect_to root_path
  end
end
