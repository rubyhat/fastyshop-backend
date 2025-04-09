# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include ApiErrorHandling
      include Pundit

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden_custom


      before_action :authenticate_user!

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
                            payload = JwtService.decode_and_verify(token)
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
