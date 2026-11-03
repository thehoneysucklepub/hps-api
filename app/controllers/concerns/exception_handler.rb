module ExceptionHandler
  class AuthenticationError < StandardError; end
  class InvalidToken        < StandardError; end
  class ExpiredToken        < StandardError; end
  class UnauthorizedError   < StandardError; end
  class NotFoundError       < StandardError; end

  extend ActiveSupport::Concern

  included do
    rescue_from ExceptionHandler::AuthenticationError do |e|
      json_error(e.message, :unauthorized)
    end

    rescue_from ExceptionHandler::InvalidToken do |e|
      # Raised without a message, Ruby uses the class name: show something readable instead
      message = e.message.presence
      message = "Please log in" if message.nil? || message == e.class.name
      json_error(message, :unauthorized)
    end

    rescue_from ExceptionHandler::ExpiredToken do |e|
      json_error("Token expired", :unauthorized)
    end

    rescue_from ExceptionHandler::UnauthorizedError do |e|
      message = e.message == e.class.name ? nil : e.message.presence
      json_error(message || "You do not have permission to do this", :forbidden)
    end

    rescue_from ExceptionHandler::NotFoundError do |e|
      json_error(e.message.presence || "Not found", :not_found)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      json_error("Record not found", :not_found)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      json_error(e.record.errors.full_messages, :unprocessable_entity)
    end
  end

  private

  def json_error(message, status)
    render json: { success: false, error: message }, status: status
  end
end
