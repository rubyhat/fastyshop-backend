# frozen_string_literal: true

# JwtService — генерация и валидация JWT access и refresh токенов.
#
# Использует алгоритм HS256 с секретным ключом из ENV["JWT_SECRET_KEY"].
# Сроки жизни и другие параметры берутся из конфигурации `Rails.application.config.jwt`.
#
# @example Генерация токенов
#   tokens = JwtService.generate_tokens(user)
#
# @example Проверка и декодирование токена
#   payload = JwtService.decode(token)

class JwtService
  class << self
    # Генерирует пару access и refresh токенов
    #
    # @param user [User]
    # @return [Hash] access_token, refresh_token
    def generate_tokens(user)
      now = Time.current
      jwt_config = Rails.application.config.x.jwt

      iat = now.to_i

      access_payload = {
        sub: user.id,
        exp: (now + jwt_config[:access_token_lifetime]).to_i,
        iat: iat,
        type: "access",
        role: user.role,
        name: user_name(user)
      }

      refresh_payload = {
        sub: user.id,
        exp: (now + jwt_config[:refresh_token_lifetime]).to_i,
        iat: iat,
        type: "refresh"
      }

      {
        access_token: JWT.encode(access_payload, jwt_config[:secret_key], "HS256"),
        refresh_token: JWT.encode(refresh_payload, jwt_config[:secret_key], "HS256"),
        iat: iat
      }
    end

    # Декодирует токен без проверки срока действия
    #
    # @param token [String]
    # @return [Hash] payload токена
    def decode(token)
      decoded = JWT.decode(token, jwt_secret, true, algorithm: "HS256")
      decoded.first.with_indifferent_access
    rescue JWT::DecodeError
      nil
    end

    # Проверяет подпись и срок действия токена
    #
    # @param token [String]
    # @return [Hash, nil] payload токена или nil если недействителен
    def decode_and_verify(token)
      JWT.decode(token, jwt_secret, true, { algorithm: "HS256" }).first.with_indifferent_access
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    private

    def jwt_secret
      Rails.application.config.jwt[:secret_key]
    end

    def user_name(user)
      user.respond_to?(:name) ? user.name : "#{user.role}_#{user.id.to_s.first(6)}"
    end
  end
end
