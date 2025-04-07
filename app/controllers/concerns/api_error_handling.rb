# frozen_string_literal: true

=begin
  TODO: locale в заголовке (например, Accept-Language: ru)
  message полностью убрать (оставить только key)
  поддержку meta (например, fields: ['email'])
  категорию ошибок: validation, auth, business, server
=end


module ApiErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from JWT::DecodeError, with: :render_invalid_token
    rescue_from JWT::ExpiredSignature, with: :render_expired_token
    rescue_from Pundit::NotAuthorizedError, with: :render_forbidden if defined?(Pundit)
  end

  private

  def render_unauthorized(message = "Unauthorized", key = "auth.unauthorized")
    render_error(key: key, message: message, status: :unauthorized, code: 401)
  end

  def render_not_found(message = "Resource not found", key = "common.not_found")
    render_error(key: key, message: message, status: :not_found, code: 404)
  end

  def render_invalid_token
    render_error(
      key: "auth.invalid_token",
      message: "Invalid token",
      status: :unauthorized,
      code: 401
    )
  end

  def render_expired_token
    render_error(
      key: "auth.token_expired",
      message: "Token expired",
      status: :unauthorized,
      code: 401
    )
  end

  def render_forbidden(message: "Access denied", key: "auth.forbidden")
    render_error(key: key, message: message, status: :forbidden, code: 403)
  end

  def render_error(key:, message:, status:, code:)
    render json: {
      error: {
        key: key,
        message: message,
        code: code,
        status: status
      }
    }, status: status
  end
end
