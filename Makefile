# Makefile — Упрощает команды Docker Compose для разработки и продакшена

# Переменные окружения по умолчанию
ENV_FILE_DEV=.env.development
ENV_FILE_PROD=.env.production

# ========================
# 👨‍💻 DEVELOPMENT
# ========================

## 🛠 Сборка dev-образа без запуска контейнеров
build-dev:
	docker compose --env-file $(ENV_FILE_DEV) build

## 🚀 Запустить dev-среду (локально с volumes и портами)
up-dev:
	docker compose --env-file $(ENV_FILE_DEV) up --build

## 🧹 Остановить и удалить dev-контейнеры и volume
clean-dev:
	docker compose --env-file $(ENV_FILE_DEV) down -v

## 🐛 Логи контейнеров dev-режима
logs-dev:
	docker compose --env-file $(ENV_FILE_DEV) logs -ft

## 🔧 Установка гемов через bundle install внутри контейнера
bundle-install:
	docker compose --env-file $(ENV_FILE_DEV) exec web bundle install

## 🔧 Создание БД, миграции и сиды (db:prepare)
db-prepare:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:prepare

## 📦 Применить только миграции (db:migrate)
db-migrate:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:migrate

## 🧪 Откат последней миграции (db:rollback)
db-rollback:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:rollback

## 🌱 Заполнить тестовыми данными из seeds.rb (db:seed)
db-seed:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:seed

## 🧬 Проверить статус миграций (db:migrate:status)
db-status:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:migrate:status

## 💬 Открыть Rails-консоль внутри контейнера
console:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails console


# ========================
# 🚀 PRODUCTION
# ========================

## 🛠 Сборка production-образа без запуска контейнеров
build-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) build

## 🚀 Запустить production (без volume и открытых портов)
up-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) up --build -d

## 🧹 Остановить и удалить продакшн контейнеры + volumes
clean-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) down -v

## 🐛 Логи продакшн-контейнеров
logs-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) logs -ft
