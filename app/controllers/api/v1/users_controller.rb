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

        render json: current_user, scope: current_user, status: :ok
      end


      # POST /api/v1/users
      def create
        authorize User, :create?

        user = Users::CreateAccount.for_admin(admin_user_params)

        if user.persisted?
          render json: user, scope: current_user, status: :created
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
          render json: user, scope: current_user, status: :ok
        else
          render_validation_errors(user)
        end
      end

      # PATCH /api/v1/users/:id/account_status
      def update_account_status
        user = User.find_by(id: params[:id])
        return render_not_found unless user

        authorize user, :update_account_status?

        status = account_status_params[:account_status].to_s

        unless User.account_statuses.key?(status)
          user.errors.add(:account_status, "недопустимый статус аккаунта")
          return render_validation_errors(user)
        end

        if user.update(account_status: status)
          render json: user, scope: current_user, status: :ok
        else
          render_validation_errors(user)
        end
      end

      # GET /api/v1/users/:id
      def show
        user = User.find_by(id: params[:id])
        return render_not_found unless user

        if user.deactivated?
          return render_user_deleted
        end

        authorize user, :show?
        render json: user, scope: current_user, status: :ok
      end

      # DELETE /api/v1/users/:id
      def destroy
        user = User.find_by(id: params[:id])
        return render_not_found unless user

        if user.deactivated?
          return render_error(
            key: "user.delete_deleted_user",
            message: "Пользователь уже был удалён ранее",
            status: :bad_request,
            code: 400
          )
        end


        authorize user, :destroy?

        if user.update(account_status: :deactivated)
          TokenStorageRedis.clear_all(user_id: user.id)

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
        render json: users, scope: current_user, status: :ok
      end

      private

      def admin_user_params
        params.require(:user).permit(
          :phone,
          :email,
          :password,
          :password_confirmation,
          :country_code,
          :role,
          :account_status,
          :first_name,
          :last_name,
          :middle_name
        )
      end

      def account_status_params
        params.permit(:account_status)
      end

      def permitted_params(user)
        params.permit(UserPolicy.new(current_user, user).permitted_update_params)
      end
    end
  end
end
