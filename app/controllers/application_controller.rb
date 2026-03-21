class ApplicationController < ActionController::API
  include ExceptionHandler

  before_action :set_default_format

  private

  def set_default_format
    request.format = :json
  end

  def authenticate_user!
    token = extract_token
    raise ExceptionHandler::InvalidToken unless token

    payload = JsonWebToken.decode(token)
    @current_user = User.find(payload[:user_id])

    raise ExceptionHandler::AuthenticationError, "Account disabled" unless @current_user.active?
  rescue ActiveRecord::RecordNotFound
    raise ExceptionHandler::InvalidToken
  end

  def current_user
    @current_user
  end

  def require_admin!
    authenticate_user!
    raise ExceptionHandler::UnauthorizedError unless current_user.can_manage?
  end

  def require_super_admin!
    authenticate_user!
    raise ExceptionHandler::UnauthorizedError unless current_user.super_admin?
  end

  def extract_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  def json_success(data = {}, status: :ok, meta: nil)
    response = { success: true }
    response.merge!(data) if data.is_a?(Hash)
    response[:meta] = meta if meta
    render json: response, status: status
  end

  def paginate(collection)
    collection.page(params[:page] || 1).per(params[:per_page] || 20)
  end
  def require_staff_or_admin!
  authenticate_user!
  raise ExceptionHandler::UnauthorizedError unless current_user.can_manage?
  end
  def audit(action:, resource: nil, resource_id: nil, details: nil)
    AuditLog.record(
      user: current_user,
      action: action,
      resource: resource,
      resource_id: resource_id,
      details: details,
      ip: request.remote_ip
    )
  end
end