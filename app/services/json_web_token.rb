class JsonWebToken
  SECRET = ENV.fetch("JWT_SECRET") { raise "JWT_SECRET not set!" }
  ACCESS_EXPIRY  = 15.minutes
  REFRESH_EXPIRY = 7.days

  def self.encode_access(payload)
    payload = payload.merge(
      exp: ACCESS_EXPIRY.from_now.to_i,
      iat: Time.now.to_i,
      type: "access"
    )
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.encode_refresh(payload)
    payload = payload.merge(
      exp: REFRESH_EXPIRY.from_now.to_i,
      iat: Time.now.to_i,
      type: "refresh"
    )
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: "HS256")
    HashWithIndifferentAccess.new(decoded[0])
  rescue JWT::ExpiredSignature
    raise ExceptionHandler::ExpiredToken
  rescue JWT::DecodeError
    raise ExceptionHandler::InvalidToken
  end
end