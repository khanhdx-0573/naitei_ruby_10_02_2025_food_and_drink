class Api::V1::BaseController < ApplicationController
  before_action :authenticate_requested_user
  attr_reader :current_user

  private
  def authenticate_requested_user
    header = request.headers["Authorization"]
    token = header.split(" ").last if header
    decoded_token = JsonWebToken.decode(token)
    @current_user = User.find_by(id: decoded_token[:user_id]) if decoded_token
    return if @current_user

    render json: {error: I18n.t("error_response.unauthorized")},
           status: :unauthorized
  end
end
