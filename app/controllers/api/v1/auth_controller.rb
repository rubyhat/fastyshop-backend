# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [ :signup, :login, :refresh ]

      # POST /auth/signup
      #
      # Регистрирует публичного пользователя, выдаёт access_token + refresh_token
      # и оставляет аккаунт в статусе ручной проверки.
      def signup
        user = Users::CreateAccount.for_signup(signup_params)

        if user.persisted?
          render_auth_payload(user, status: :created)
        else
          render_validation_errors(user)
        end
      end

      # POST /auth/login
      #
      # Аутентифицирует пользователя по номеру телефона и паролю,
      # выдает access_token + refresh_token, сохраняет refresh в Redis.
      def login
        phone = User.normalize_phone(login_params[:phone])
        password = login_params[:password]

        user = User.find_by(phone: phone)

        if user&.authenticatable? && user.authenticate(password)
          render_auth_payload(user, status: :ok)
        else
          render_error(
            key: "auth.invalid_credentials",
            message: "Неверный логин или пароль",
            status: :unauthorized,
            code: 401
          )
        end
      end

      # POST /auth/refresh
      #
      # Проверяет refresh_token, если валиден — выдает новую пару токенов.
      def refresh
        payload = JwtService.decode_and_verify(params[:refresh_token])

        if payload.present? && payload["type"] == "refresh"
          user = User.find_by(id: payload["sub"])

          if user&.authenticatable? && TokenStorageRedis.valid?(user_id: user.id, session_id: payload["sid"], iat: payload["iat"])
            tokens = JwtService.generate_tokens(user, session_id: payload["sid"])
            TokenStorageRedis.save(user_id: user.id, session_id: tokens[:session_id], iat: tokens[:iat])

            render json: {
              access_token: tokens[:access_token],
              refresh_token: tokens[:refresh_token]
            }, status: :ok
          else
            render_error(
              key: "auth.invalid_refresh_token",
              message: "Refresh token is invalid or expired",
              status: :unauthorized,
              code: 401
            )
          end
        else
          render_invalid_token
        end
      end

      # POST /auth/logout
      #
      # Удаляет refresh_token пользователя из Redis.
      def logout
        token = request.headers["Authorization"]&.split&.last
        payload = JwtService.decode(token)

        if payload && payload["sub"] && payload["sid"]
          TokenStorageRedis.clear(user_id: payload["sub"], session_id: payload["sid"])
        end

        render_success(key: "auth.logout", message: "Вы вышли из системы")
      end

      private

      def signup_params
        params.require(:user).permit(:phone, :email, :password, :password_confirmation, :country_code, :first_name, :last_name, :middle_name)
      end

      def login_params
        params.permit(:phone, :password)
      end

      def render_auth_payload(user, status:)
        tokens = JwtService.generate_tokens(user)
        TokenStorageRedis.save(user_id: user.id, session_id: tokens[:session_id], iat: tokens[:iat])

        render json: {
          user: serialized_user(user),
          access_token: tokens[:access_token],
          refresh_token: tokens[:refresh_token]
        }, status: status
      end

      def serialized_user(user)
        ActiveModelSerializers::SerializableResource.new(user, scope: user).as_json
      end
    end
  end
end
