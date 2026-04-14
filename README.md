# 🧠 Fastyshop Backend (Rails API-only)

Это backend-часть проекта **Fastyshop** — SaaS-платформа для создания интернет-магазинов с акцентом на mobile-first, модульную архитектуру и безопасность.

---

## 📦 Используемый стек

- **Ruby** 4.0.2
- **Rails** 8.1.3 (API-only)
- **PostgreSQL** 17
- **Redis** 7.4
- **Docker** + Docker Compose
- **Bundler**
- **Makefile** для упрощения dev/prod команд

---

## 👨‍💻 Полный цикл запуска для нового разработчика

Если ты впервые работаешь с этим проектом — вот пошаговая инструкция, как развернуть его с нуля:

### 1. 🔧 Установи необходимые зависимости

Убедись, что у тебя установлены:

- [Docker](https://www.docker.com/) (Docker Desktop)
- [Make](https://www.gnu.org/software/make/) (обычно уже установлен на macOS и Linux)
- [Git](https://git-scm.com/)

### 2. 📥 Склонируй репозиторий

```bash
git clone https://github.com/your-username/fastyshop-backend.git
cd fastyshop-backend
```

### 3. 🛠 Создай файлы окружения

```bash
cp .env.example .env.development
cp .env.example .env.production
```

⚠️ Проверь `.env.development` и `.env.production` — задай значения переменным

### 4. 🐳 Подними проект в dev-режиме

```bash
make up-dev
```

⏳ Это займет немного времени при первом запуске (скачивание образов и установка гемов).

После запуска будет доступно по адресу:  
👉 http://localhost:3000

### 5. 🗄️ Проведи миграции и создавай схемы БД

```bash
make db-setup-dev
```

📦 Эта команда создаёт базу данных, применяет все миграции и запускает сиды.

---

📌 Готово! Теперь ты можешь:

- создавать новые модели
- работать с API
- запускать миграции с помощью `make db-migrate-dev`
- откатывать миграции `make db-rollback-dev`
- смотреть логи `make logs-dev`

---

## 🔄 Пример полного рабочего цикла

```bash
# 1. Остановка всех старых контейнеров
docker compose down -v --remove-orphans

# 2. Удаление старых образов
docker image prune -f

# 3. Пересборка проекта с нуля
docker compose --env-file .env.development build --no-cache

# 4. Запуск проекта
make up-dev

# 5. Применение миграций (если есть новые)
make db-migrate

# 6. (по необходимости) Засеять базу начальными данными
make db-seed
```

---

## 🚀 Быстрый старт

### 🔧 Установка зависимостей

```bash
cp .env.example .env.development
cp .env.example .env.production
```

### 👨‍💻 Запуск в режиме разработки

```bash
make up-dev
```

Доступно по адресу: [http://localhost:3000](http://localhost:3000)

### 🧼 Остановка dev-режима

```bash
make clean-dev
```

---

### 🚀 Запуск в продакшн окружении

```bash
make up-prod
```

🔐 Переменные берутся из `.env.production`

📄 Контейнеры запускаются в фоне (`-d`)

### 🧼 Остановка продакшена

```bash
make clean-prod
```

---

### 🧼 Полная очистка Docker и перезапуск

```bash
docker compose down -v --remove-orphans
docker image prune -f  # удалит старые образы
docker compose --env-file .env.development build --no-cache
make up-dev
```

---

## 📋 Makefile команды

| Команда            | Описание                                                                |
| ------------------ | ----------------------------------------------------------------------- |
| `make up-dev`      | 🚀 Запуск dev-режима с `.env.development`                               |
| `make clean-dev`   | 🧹 Остановка и удаление dev-контейнеров и volume                        |
| `make logs-dev`    | 🐛 Просмотр логов контейнеров в dev                                     |
| `make build-dev`   | 🛠 Сборка образов dev-окружения                                          |
| `make db-migrate`  | 📦 Выполнить миграции в dev-контейнере после изменения/добавления схемы |
| `make db-setup`    | 📋 Создание базы данных + миграции + сиды в dev-режиме                  |
| `make db-seed`     | 🌱 Засидить (seed) данные в базу (после миграций или вручную)           |
| `make db-rollback` | ⬅️ Откатить последнюю миграцию в dev                                    |
| `make db-reset`    | ♻️ Удалить БД, пересоздать, мигрировать и засеять                       |
| `make up-prod`     | 🚀 Запуск production-режима с `.env.production`                         |
| `make clean-prod`  | 🧹 Остановка и удаление prod-контейнеров и volume                       |
| `make logs-prod`   | 🐛 Просмотр логов в продакшене                                          |
| `make build-prod`  | 🛠 Сборка образов production-окружения                                   |

---

## 🧪 Когда использовать миграции и сиды?

После каждого добавления, изменения или удаления модели, таблицы или колонки:

### 1. 📦 Применить миграции:

```bash
make db-migrate
```

Если база ещё не создана (например, при первом запуске проекта), можно использовать:

```bash
make db-setup
```

### 2. 🌱 Засеять тестовые данные:

```bash
make db-seed
```

Если хочешь пересоздать всё с нуля:

```bash
make db-reset
```

---

## 🐳 Структура Docker Compose

- `docker-compose.yml` — основа (web, db, redis)
- `docker-compose.override.yml` — накладывает development-настройки
- `docker-compose.prod.yml` — накладывает production-настройки
- `.env.development`, `.env.production` — переменные окружения

---

## 📁 Структура проекта (фрагмент)

```
fastyshop-backend/
├── Dockerfile
├── docker-compose.yml
├── docker-compose.override.yml
├── docker-compose.prod.yml
├── Makefile
├── .env.development
├── .env.production
├── README.md
└── ...
```

## Полезные команды
Просмотр существующих БД:
```
psql -h localhost -U postgres -p 5432 -l
```

Проверка возможности подключиться к порту:
```
nc -zv localhost 5432
```

Проверка к чему есть доступ в классе:
```
make console
Api::V1::AuthController.ancestors
```
