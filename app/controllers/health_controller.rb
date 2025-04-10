# frozen_string_literal: true

class HealthController < ActionController::API
  # GET /status
  #
  # Проверяет базовые сервисы приложения: Postgres и Redis.
  # Возвращает JSON с деталями по каждому компоненту.
  def status
    checks = {
      database: check_database,
      redis: check_redis
    }

    all_ok = checks.values.all? { |check| check[:status] == "ok" }

    render json: {
      status: all_ok ? "ok" : "fail",
      services: checks
    }, status: (all_ok ? :ok : :service_unavailable)
  end

  private

  def check_database
    ActiveRecord::Base.connection.active?
    { status: "ok", message: "PostgreSQL работает" }
  rescue => e
    { status: "fail", message: "Ошибка PostgreSQL: #{e.message}" }
  end

  def check_redis
    redis = Redis.new(url: ENV.fetch("REDIS_URL", nil))
    if redis.ping == "PONG"
      { status: "ok", message: "Redis отвечает PONG" }
    else
      { status: "fail", message: "Redis не ответил" }
    end
  rescue => e
    { status: "fail", message: "Ошибка Redis: #{e.message}" }
  end
end
