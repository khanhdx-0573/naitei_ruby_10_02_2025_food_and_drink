class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  USER_PARAMS = %i(name email password password_confirmation).freeze

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: USER_PARAMS)
    devise_parameter_sanitizer.permit(:account_update, keys: USER_PARAMS)
  end

  def after_sign_up_path_for resource
    stored_location_for(resource) || root_path
  end
end
