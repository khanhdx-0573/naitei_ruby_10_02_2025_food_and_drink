class ApplicationController < ActionController::Base
  include Pagy::Backend
  include CanCan::ControllerAdditions
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
    authorize! :manage_product, Product
    authorize! :manage_order, Order
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json do
        render json: {error: exception.message}, status: :forbidden
      end
      format.html do
        flash[:danger] = exception.message
        redirect_to root_path
      end
    end
  end
end
