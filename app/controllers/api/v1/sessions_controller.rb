class Api::V1::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token
  respond_to :json

  def create
    user = User.find_for_database_authentication(email: params[:email])
    if user&.valid_password?(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: {token:, user:}, status: :ok
    else
      render json: {error: t("error_response.invalid_credentials")},
             status: :unauthorized
    end
  end

  def destroy
    head :no_content
  end
end
