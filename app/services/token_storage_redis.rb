# frozen_string_literal: true

# TokenStorageRedis — сервис для хранения и проверки refresh-токенов в Redis.
#
# Используется для безопасной реализации logout и контроля живых сессий.

class TokenStorageRedis
  class << self
    # Сохраняет refresh токен (точнее, его iat) в Redis
    #
    # @param user_id [String]
    # @param iat [Integer] метка времени создания токена
    def save(user_id:, iat:)
      redis.setex(redis_key(user_id), refresh_ttl, iat.to_s)
    end

    # Проверяет, совпадает ли переданный iat с сохранённым в Redis
    #
    # @param user_id [String]
    # @param iat [Integer]
    # @return [Boolean]
    def valid?(user_id:, iat:)
      stored_iat = redis.get(redis_key(user_id))
      stored_iat.present? && stored_iat == iat.to_s
    end

    # Удаляет refresh-токен пользователя (logout)
    #
    # @param user_id [String]
    def clear(user_id:)
      redis.del(redis_key(user_id))
    end

    private

    def redis_key(user_id)
      "refresh:#{user_id}"
    end

    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    end

    def refresh_ttl
      Rails.application.config.jwt[:refresh_token_lifetime]
    end
  end
end
