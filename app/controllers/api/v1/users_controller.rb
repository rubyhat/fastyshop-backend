# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      # GET /api/v1/me
      #
      # Возвращает текущего авторизованного пользователя.
      # Использует current_user, установленный в BaseController.
      def me
        user = current_user

        if user
          render json: current_user, status: :ok
        else
          render_unauthorized
        end
      end
    end
  end
end
