# frozen_string_literal: true

require "pp"

module Api
  module V1
    class BaseController < ApplicationController
      include ApiErrorHandling
      include Pundit::Authorization

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden_custom

      # Базовая обработка ошибок 500+ todo: надо протестить
      rescue_from StandardError do |exception|
        logger.error "[#{exception.class}] #{exception.message}"
        logger.error exception.backtrace.join("\n") if Rails.env.development? || Rails.env.test?

        render json: {
          status: 500,
          error: "Internal Server Error",
          message: exception.message,
          class: exception.class.name
        }, status: :internal_server_error
      end


      before_action :authenticate_user!
      before_action { Current.user = current_user }


      private

      def render_forbidden_custom
        render_forbidden(message: "Доступ запрещен.", key: "base.forbidden")
      end


      # Аутентификация пользователя по access-токену
      def authenticate_user!
        render_unauthorized unless current_user
      end

      # Возвращает текущего пользователя на основе токена
      #
      # @return [User, nil]
      def current_user
        @current_user ||= begin
                            token = request.headers["Authorization"]&.split&.last
                            pp "JWT TOKEN"
                            pp token
                            payload = JwtService.decode_and_verify(token && token)
                            pp "JWT PAYLOAD"
                            pp payload
                            if payload.present? && payload["type"] == "access"
                              User.find_by(id: payload["sub"])
                            else
                              nil
                            end
                          end
      end
    end
  end
end
