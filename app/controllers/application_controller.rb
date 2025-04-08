class ApplicationController < ActionController::Base
  include Pagy::Backend
  include SessionsHelper
  include DeviseHelper
  before_action :set_locale
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def logged_in_user?
    return if user_signed_in?

    flash[:danger] = t "user.please_login"
    redirect_to login_path
  end

  def authorize_admin
    return if current_user.admin?

    flash[:danger] = t "user.permission_denied"
    redirect_to root_path
  end
end
