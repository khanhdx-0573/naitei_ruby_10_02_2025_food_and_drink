class JsonWebToken
  SECRET_KEY = ENV["JWT_SECRET_KEY"]

  def self.encode payload, exp = ENV["JWT_EXPIRED_TIME"].hours.from_now
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode token
    return nil unless token

    begin
      body = JWT.decode(token, SECRET_KEY)[0]
      HashWithIndifferentAccess.new(body)
    rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
      nil
    end
  end
end
