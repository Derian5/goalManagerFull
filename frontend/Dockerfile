# Этап 1: Сборка Flutter Web-приложения
FROM ghcr.io/cirruslabs/flutter:3.38.0 AS builder

WORKDIR /app

# Копируем файлы проекта и устанавливаем зависимости
COPY . .
RUN flutter pub get

# Собираем веб-версию приложения в релизном режиме
RUN flutter build web --release
RUN apt-get update && apt-get install -y iputils-ping && rm -rf /var/lib/apt/lists/*


# Этап 2: Запуск через Nginx
FROM nginx:alpine

# Копируем собранные файлы из первого этапа в стандартную папку Nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf


# Nginx по умолчанию слушает 80-й порт
EXPOSE 80