class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:success, :signed_in)
    sign_in(resource_name, resource)
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  def destroy
    signed_out = if Devise.sign_out_all_scopes
                   sign_out
                 else
                   sign_out(resource_name)
                 end
    set_flash_message!(:success, :signed_out) if signed_out
    respond_to_on_destroy
  end

  protected

  def after_sign_in_path_for resource
    stored_location_for(resource) || root_path
  end
end
