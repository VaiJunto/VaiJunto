# Flutter SDK pinned na mesma versão usada localmente (ver REQUIREMENTS.md
# secao 1 - 3.35.7 e o sweet spot de AGP/16KB para os plugins deste projeto).
FROM ghcr.io/cirruslabs/flutter:3.35.7 AS build

WORKDIR /app

# API_BASE_URL de producao como build-arg: o valor e compilado dentro do
# main.dart.js (String.fromEnvironment e resolvido em build-time, nao da
# para trocar depois so reiniciando o container). Ver mobile/lib/core/network/api_client.dart.
ARG API_BASE_URL=https://api.vaijunto.app.br/api/v1
ARG WS_BASE_URL=wss://api.vaijunto.app.br/ws-tracking
ARG BUILD_REVISION=local

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=WS_BASE_URL=${WS_BASE_URL} \
    --dart-define=BUILD_REVISION=${BUILD_REVISION}

FROM nginx:1.27-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
