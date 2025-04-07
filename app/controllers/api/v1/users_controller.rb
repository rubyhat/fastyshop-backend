# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      # GET /api/v1/me
      #
      # Возвращает текущего авторизованного пользователя.
      # Использует current_user, установленный в BaseController.
      def me
        authorize current_user, :me?

        render json: current_user, status: :ok
      end
    end
  end
end
