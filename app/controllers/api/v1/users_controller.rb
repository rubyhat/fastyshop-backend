# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: %i[create show]

      # GET /api/v1/me
      #
      # Возвращает текущего авторизованного пользователя.
      # Использует current_user, установленный в BaseController.
      def me
        authorize current_user, :me?

        render json: current_user, status: :ok
      end


      # POST /api/v1/users
      def create
        user = User.new(user_params)

        # Принудительно назначаем роль user, игнорируем любую переданную
        user.role = 3

        # Запрет на создание superadmin
        if user.superadmin?
          return render_forbidden(message: "Создание superadmin запрещено", key: "users.superadmin_not_allowed")
        end

        if user.save
          render json: user, status: :created
        else
          render_validation_errors(user)
        end
      end

      # PATCH /api/v1/users/:id
      def update
        user = User.find_by(id: params[:id])
        return render_not_found unless user

        authorize user, :update?

        if user.update(permitted_params(user))
          render json: user, status: :ok
        else
          render_validation_errors(user)
        end
      end

      # GET /api/v1/users/:id
      def show
        user = User.find_by(id: params[:id])
        return render_not_found unless user

        unless user.is_active
          return render_user_deleted
        end

        authorize user, :show?
        render json: user, status: :ok
      end

      # DELETE /api/v1/users/:id
      def destroy
        user = User.find_by(id: params[:id])
        return render_not_found unless user

        unless user.is_active
          return render_error(
            key: "user.delete_deleted_user",
            message: "Пользователь уже был удалён ранее",
            status: :bad_request,
            code: 400
          )
        end


        authorize user, :destroy?

        if user.update(is_active: false)
          render_success(
            key: "users.deleted",
            message: "Пользователь успешно удалён (деактивирован)",
            code: 200
          )
        else
          render_validation_errors(user)
        end
      end

      # GET /api/v1/users
      def index
        users = policy_scope(User)
        render json: users, status: :ok
      end

      private

      def user_params
        params.permit(:phone, :email, :password, :password_confirmation, :country_code)
      end

      def permitted_params(user)
        params.permit(UserPolicy.new(current_user, user).permitted_update_params)
      end
    end
  end
end
