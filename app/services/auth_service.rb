class AuthService
  def self.login(username_or_email:, password:, ip: nil, user_agent: nil)
    user = User.find_by(username: username_or_email) ||
           User.find_by(email: username_or_email)

    raise ExceptionHandler::AuthenticationError, "Invalid credentials" unless user
    raise ExceptionHandler::AuthenticationError, "Account disabled" unless user.active?
    raise ExceptionHandler::AuthenticationError, "Invalid credentials" unless user.authenticate(password)

    tokens = issue_tokens(user, ip: ip, user_agent: user_agent)
    user.update_column(:last_login_at, Time.now)

    AuditLog.record(user: user, action: "login", ip: ip)

    { user: user, **tokens }
  end

  def self.refresh(token_string:, ip: nil)
    payload = JsonWebToken.decode(token_string)

    raise ExceptionHandler::InvalidToken unless payload[:type] == "refresh"

    db_token = RefreshToken.active.find_by(token: token_string)
    raise ExceptionHandler::InvalidToken, "Token revoked or expired" unless db_token

    user = db_token.user
    raise ExceptionHandler::AuthenticationError, "Account disabled" unless user.active?

    db_token.update!(revoked: true)

    issue_tokens(user, ip: ip)
  end

  def self.logout(token_string:)
    db_token = RefreshToken.find_by(token: token_string)
    db_token&.update!(revoked: true)
    true
  end

  def self.issue_tokens(user, ip: nil, user_agent: nil)
    payload = {
      user_id: user.id,
      username: user.username,
      role: user.role,
      branch_id: user.branch_id
    }

    access_token  = JsonWebToken.encode_access(payload)
    refresh_token = JsonWebToken.encode_refresh(payload)

    RefreshToken.create!(
      user: user,
      token: refresh_token,
      expires_at: 7.days.from_now,
      ip_address: ip,
      user_agent: user_agent
    )

    { access_token: access_token, refresh_token: refresh_token }
  end
  private_class_method :issue_tokens
end