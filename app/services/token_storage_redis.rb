# frozen_string_literal: true

# TokenStorageRedis — сервис для хранения и проверки refresh-токенов в Redis.
#
# Используется для безопасной реализации logout и контроля живых сессий.

# todo: если сделать /logout, то рефреш удалился, но access будет жить еще access_token_ttl минут и технически,
# запросы делать можно будет. Возможно нужно также сохранять в редис access_token и следить за ним,
# чтобы повысить уровень безопасности. Можно рассмотреть после запуска mvp
class TokenStorageRedis
  class << self
    # Сохраняет refresh токен (точнее, его iat) в Redis
    #
    # @param user_id [String]
    # @param session_id [String]
    # @param iat [Integer] метка времени создания токена
    def save(user_id:, session_id:, iat:)
      redis.setex(redis_key(user_id, session_id), JwtConfig.refresh_token_ttl, iat.to_s)
    end

    # Проверяет, совпадает ли переданный iat с сохранённым в Redis
    #
    # @param user_id [String]
    # @param session_id [String]
    # @param iat [Integer]
    # @return [Boolean]
    def valid?(user_id:, session_id:, iat:)
      return false if session_id.blank?

      stored_iat = redis.get(redis_key(user_id, session_id))
      stored_iat.present? && stored_iat == iat.to_s
    end

    # Удаляет refresh-токен пользователя (logout)
    #
    # @param user_id [String]
    # @param session_id [String]
    def clear(user_id:, session_id:)
      return if session_id.blank?

      redis.del(redis_key(user_id, session_id))
    end

    # Удаляет все refresh-сессии пользователя.
    #
    # @param user_id [String]
    def clear_all(user_id:)
      redis.scan_each(match: redis_key_pattern(user_id)) do |key|
        redis.del(key)
      end
    end

    private

    def redis_key(user_id, session_id)
      "refresh:#{user_id}:#{session_id}"
    end

    def redis_key_pattern(user_id)
      "refresh:#{user_id}:*"
    end

    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    end
  end
end
