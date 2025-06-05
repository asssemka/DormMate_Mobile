# Этап сборки
FROM ubuntu:22.04 as build

# Установка зависимостей
RUN apt-get update && apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa wget ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Клонируем Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /opt/flutter && \
  cd /opt/flutter && \
  git checkout tags/3.32.1

# Устанавливаем переменные окружения
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
ENV FLUTTER_HOME="/opt/flutter"

# Включаем web-сборку и кэшируем зависимости
RUN flutter config --enable-web && flutter precache

# Создаем пользователя flutter
RUN useradd -ms /bin/bash flutter

# Копируем проект
WORKDIR /app
COPY . .

# Устанавливаем зависимости
RUN flutter pub get

# Даем права пользователю flutter
RUN chown -R flutter:flutter /opt/flutter /app

# Переключаемся на пользователя
USER flutter

# Убираем ошибку Git "dubious ownership"
RUN git config --global --add safe.directory /opt/flutter

# Сборка проекта во Flutter Web
RUN flutter build web

# Этап публикации (второй слой)
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Открываем порт
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
