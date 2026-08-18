# Deploy — VaiJunto (produção)

> Documenta o fluxo de CI/CD e a topologia da VPS. Os arquivos citados como
> "na VPS" (`docker-compose.yml`, `.env`, `deploy.sh`, script de backup) **não
> estão neste repositório** — vivem só no servidor. Este documento é a
> referência para conferir/reconstruir esses arquivos, não um substituto
> automático deles.

## 1. Fluxo

```text
push/merge na main
  → GitHub Actions (.github/workflows/deploy.yml)
    → build-backend: imagem Docker (contexto: backend/, Dockerfile: backend/Dockerfile)
        → push para ghcr.io/vaijunto/vaijunto-backend:latest
                    e ghcr.io/vaijunto/vaijunto-backend:sha-<commit>
    → build-web: imagem Docker do Flutter Web/PWA (contexto: mobile/, Dockerfile: mobile/Dockerfile)
        → build-arg API_BASE_URL=https://api.vaijunto.app.br/api/v1 (compilado no bundle,
          ver mobile/lib/core/network/api_client.dart)
        → push para ghcr.io/vaijunto/vaijunto-web:latest
                    e ghcr.io/vaijunto/vaijunto-web:sha-<commit>
    → aguarda aprovação do environment "production" (depende dos dois builds acima)
  → (usuário aprova no GitHub)
  → SSH na VPS (secrets VPS_HOST / VPS_USER / VPS_SSH_KEY)
    → executa /opt/apps/vaijunto/deploy.sh
      → docker compose pull
      → docker compose up -d
  → api.vaijunto.app.br e vaijunto.app.br atualizados
```

A tag `sha-<commit>` é publicada para permitir rollback manual (fixar
`BACKEND_IMAGE` no `.env` da VPS para um SHA específico e rodar
`docker compose up -d` de novo) sem depender de `:latest` sempre apontar
para o build mais recente.

## 2. Topologia na VPS (`/opt/apps/vaijunto/`)

```text
/opt/apps/vaijunto/
├── docker-compose.yml   # não versionado aqui — ver seção 2.1
├── .env                 # não versionado aqui, nunca deve ser
├── deploy.sh
└── data/postgres/
```

### 2.1 Referência de `docker-compose.yml` de produção

Modelo para conferir contra o que está de fato na VPS (nomes de serviço,
variáveis e binds de porta são o que importa — não precisa ser idêntico
byte a byte):

```yaml
services:
  db:
    image: postgis/postgis:16-3.4
    container_name: vaijunto-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    # SEM "ports:" — 5432 fica só na rede interna do compose, não no host.
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: ${BACKEND_IMAGE}
    container_name: vaijunto-backend
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: ${POSTGRES_DB}
      DB_USER: ${POSTGRES_USER}
      DB_PASS: ${POSTGRES_PASSWORD}
      MAIL_USERNAME: ${MAIL_USERNAME}
      MAIL_PASSWORD: ${MAIL_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      CORS_ALLOWED_ORIGINS: ${CORS_ALLOWED_ORIGINS}
    ports:
      - "127.0.0.1:8080:8080"   # só loopback — Caddy é quem expõe pra internet

  web:
    image: ${WEB_IMAGE}
    container_name: vaijunto-web
    restart: unless-stopped
    # SEM "depends_on: backend" — o PWA e estático (nginx servindo o build do
    # Flutter Web), a URL da API ja foi compilada no bundle via API_BASE_URL
    # (build-arg do mobile/Dockerfile). Não precisa do backend no ar pra subir.
    ports:
      - "127.0.0.1:8081:80"   # só loopback — mesmo padrão do backend, Caddy expõe pra internet
```

### 2.2 Caddyfile de referência (roteamento por domínio)

Modelo para conferir contra o Caddyfile real da VPS — dois domínios, cada um
apontando para o container correspondente via loopback:

```caddyfile
vaijunto.app.br {
    reverse_proxy 127.0.0.1:8081
}

api.vaijunto.app.br {
    reverse_proxy 127.0.0.1:8080
}
```

Caddy cuida do certificado HTTPS de ambos os domínios automaticamente (ACME/Let's
Encrypt) — nenhuma configuração extra de TLS é necessária aqui.

**Nota sobre nomes de variável de banco**: o `.env` atual da VPS usa
`SPRING_DATASOURCE_URL` / `SPRING_DATASOURCE_USERNAME` /
`SPRING_DATASOURCE_PASSWORD` diretamente. Isso funciona — o Spring Boot faz
bind relaxado dessas variáveis de ambiente para `spring.datasource.*`, com
prioridade maior que o `application.yml` — mas é uma convenção diferente da
que o próprio `application.yml` documenta (`DB_HOST`, `DB_PORT`, `DB_NAME`,
`DB_USER`, `DB_PASS`, ver [backend/src/main/resources/application.yml](backend/src/main/resources/application.yml)
e [REQUIREMENTS.md](REQUIREMENTS.md#51-banco-de-dados--postgresql-nativo-não-use-o-docker)).
**Não é um bug** — não precisa mexer no `.env` já funcionando na VPS — mas
se for recriar o `.env` do zero, prefira `DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASS`
para ficar alinhado com o resto do projeto.

### 2.3 `.env` da VPS — variáveis esperadas

```env
POSTGRES_DB=vaijunto
POSTGRES_USER=vaijunto
POSTGRES_PASSWORD=<secreto>

# ver nota acima — DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASS (recomendado)
# ou SPRING_DATASOURCE_URL/USERNAME/PASSWORD (o que já está em uso)

MAIL_USERNAME=<secreto>
MAIL_PASSWORD=<secreto>
JWT_SECRET=<secreto, gerar um valor forte próprio — não usar o default do application.yml>

# Origem do PWA liberada no CORS do backend (ver SecurityConfig.java). Sem
# essa variável, o backend cai no default de dev (localhost) e o vaijunto.app.br
# em produção não consegue chamar a API (bloqueado por CORS no navegador).
CORS_ALLOWED_ORIGINS=https://vaijunto.app.br

# Imagem do frontend (Flutter Web/PWA) publicada pelo job build-web do CI.
WEB_IMAGE=ghcr.io/vaijunto/vaijunto-web:latest

BACKEND_IMAGE=ghcr.io/vaijunto/vaijunto-backend:latest
```

⚠️ `jwt.secret` no [application.yml](backend/src/main/resources/application.yml)
tem um valor default hardcoded. Ele só é usado se `JWT_SECRET` não estiver
definido — **confirme que a VPS define `JWT_SECRET` com um valor próprio**,
nunca o default do repositório (esse default vale para dev local).

### 2.4 `deploy.sh` (conteúdo real, confirmado em `/opt/apps/vaijunto/deploy.sh`)

```bash
#!/bin/bash
set -e

cd /opt/apps/vaijunto

echo ">>> Baixando imagens novas..."
docker compose pull

echo ">>> Aplicando atualização..."
docker compose up -d --remove-orphans

echo ">>> Limpando imagens antigas..."
docker image prune -f

echo ">>> Deploy concluído."
docker compose ps
```

Auditado — **sem problemas**. `--remove-orphans` remove containers de serviços
que saíram do compose; `docker image prune -f` é seguro aqui porque só limpa
imagens *dangling* (a versão anterior de `:latest` vira dangling assim que a
nova é pulled, então ela é limpa — não afeta a tag `sha-<commit>` publicada
pelo CI, que fica retida até ser explicitamente removida).

Melhoria opcional (não aplicada — é infra viva na VPS, exige ação manual):
o script não verifica se o backend ficou saudável depois do `up -d` (compose
só espera os containers *iniciarem*, não o healthcheck do Spring Boot passar).
Adicionar ao final algo como:

```bash
echo ">>> Verificando saúde do backend..."
for i in $(seq 1 15); do
  curl -fs http://127.0.0.1:8080/actuator/health && break
  sleep 2
done
curl -fs http://127.0.0.1:8080/actuator/health || { echo "!!! Backend não respondeu saudável após o deploy"; exit 1; }
```

Isso faz o job do GitHub Actions falhar (e te avisar) se o deploy subiu um
container que não fica saudável, em vez de reportar sucesso só porque o
container iniciou.

## 3. Segurança (checklist do que já está decidido — não regredir)

- [x] SSH por chave; login root e por senha desabilitados
- [x] UFW liberando só 22, 80, 443
- [x] Postgres sem bind de porta pública (só rede interna do compose)
- [x] Backend só em `127.0.0.1:8080`, nunca exposto direto
- [x] Frontend (Flutter Web/PWA) só em `127.0.0.1:8081`, nunca exposto direto — mesmo padrão do backend
- [x] Caddy na frente, HTTPS ativo em `vaijunto.app.br` / `api.vaijunto.app.br`
- [x] Usuário `deploy` dedicado, sem sudo geral
- [x] Deploy só via GitHub Actions + environment `production` com aprovação manual
- [x] Secrets (`VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`) fora do YAML, só em GitHub Secrets
- [x] `.env` da VPS nunca versionado

Qualquer mudança que exponha `5432` ou `8080` publicamente, remova a
aprovação do environment, ou coloque credenciais no workflow **reduz essa
postura** — não faça sem confirmar antes.

## 4. Backup do Postgres (`/usr/local/bin/backup-vaijunto-db.sh`)

### 4.1 Conteúdo real (confirmado)

```bash
#!/bin/bash
set -e

BACKUP_DIR="/opt/backups/vaijunto"
DATE=$(date +"%Y-%m-%d_%H-%M")

docker exec vaijunto-db pg_dump -U vaijunto vaijunto | gzip > "$BACKUP_DIR/vaijunto_$DATE.sql.gz"

find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +7 -delete
```

### 4.2 Avaliação

- ✅ Timestamp no nome (`vaijunto_$DATE.sql.gz`) — nunca sobrescreve o
  backup anterior.
- ✅ Retenção limitada — `-mtime +7` apaga o que passou de 7 dias.
- ✅ `pg_dump` + `gzip` — dump comprimido do banco certo (`vaijunto`, user
  `vaijunto`, container `vaijunto-db` — bate com a topologia real).
- 🔴 **Bug: falha silenciosa.** `set -e` não propaga erro de dentro de um
  pipe — só olha o *exit code do último comando do pipe* (`gzip`). Se o
  `pg_dump` falhar (banco fora do ar, credencial errada, disco cheio no
  container), o `gzip` recebe um stdin vazio, comprime "nada" com sucesso, e
  o script termina com exit 0. Resultado: um `.sql.gz` de poucos bytes,
  cron reporta sucesso, e **ninguém percebe que o backup daquele dia está
  vazio** até precisar restaurar. Isso é exatamente o risco que você pediu
  para eliminar ("falhas possam ser percebidas").
- ⚠️ Não verifica se `BACKUP_DIR` existe antes de gravar (se o diretório
  for removido/não montado, o dump falha silenciosamente pelo mesmo motivo
  acima).
- ℹ️ Não é bug, é opção válida: dump em SQL texto (`.sql.gz`) em vez de
  formato custom (`-Fc`) — funciona bem para restore completo; só não
  permite restore seletivo por tabela nem `pg_restore -j` paralelo. Não
  precisa mudar isso, só citando a troca implícita.

### 4.3 Correção sugerida (não aplicada — script vive só na VPS, você decide quando trocar)

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/backups/vaijunto"
DATE=$(date +"%Y-%m-%d_%H-%M")
DUMP_FILE="$BACKUP_DIR/vaijunto_$DATE.sql.gz"

mkdir -p "$BACKUP_DIR"

if ! docker exec vaijunto-db pg_dump -U vaijunto vaijunto | gzip > "$DUMP_FILE"; then
  echo "ERRO: pg_dump/gzip falhou — removendo dump incompleto $DUMP_FILE" >&2
  rm -f "$DUMP_FILE"
  exit 1
fi

if [ ! -s "$DUMP_FILE" ]; then
  echo "ERRO: dump gerado está vazio ($DUMP_FILE)" >&2
  rm -f "$DUMP_FILE"
  exit 1
fi

find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +7 -delete
```

O que muda:
- `pipefail` — agora `set -e` também mata o script se `pg_dump` falhar
  dentro do pipe.
- `mkdir -p` defensivo no diretório de destino.
- Checa explicitamente se o arquivo final não ficou vazio (`-s`) e remove
  o dump incompleto em vez de deixá-lo lá como se fosse válido.
- Continua com `-mtime +7`, mesmo nome de arquivo, mesmo comando de dump —
  só fecha a brecha de falha silenciosa.

**Ainda depende de você**: para saber se o backup *rodou* (não só se não
deu erro), confira se o crontab (`0 3 * * * /usr/local/bin/backup-vaijunto-db.sh`)
redireciona stdout/stderr para algum lugar visível — sem isso, um `cron`
sem MTA configurado descarta a saída e um erro (agora que ele existe de
verdade) só aparece se alguém for olhar o log manualmente. Redirecionar
para um log (`>> /var/log/vaijunto-backup.log 2>&1`) ou usar `chronic`/um
serviço de heartbeat (healthchecks.io, cron-monitor) resolve isso.

## 5. Desenvolvimento local (não depende da VPS)

- Backend: `mvn spring-boot:run` (Postgres nativo, ver [REQUIREMENTS.md](REQUIREMENTS.md)) —
  ou `docker compose up` na raiz do repo, que sobe o Postgres/PostGIS local
  (`docker-compose.yml`, só banco, sem backend — o backend continua rodando
  via Maven/IDE).
- Mobile: `./dev.ps1` (device físico) ou `./dev.ps1 -Web` (Chrome/hot reload).
  Sem `--dart-define`, o app aponta para `http://127.0.0.1:8080/api/v1`
  (ver [mobile/lib/core/network/api_client.dart](mobile/lib/core/network/api_client.dart)).

### 5.1 Build de produção do app mobile (Android)

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.vaijunto.app.br/api/v1
```

Sem essa flag, o build usa o default de dev (`127.0.0.1:8080`) — build de
release feito sem `--dart-define` **não vai funcionar fora da rede local**.

### 5.2 Flutter Web / PWA

Atualizado em 2026-08-13: Flutter Web passou a ser uma plataforma real do
projeto, além do Android — não substitui o mobile, é um segundo target
publicado em `vaijunto.app.br` (ver seção 2). `mobile/web/` é gerado com:

```bash
cd mobile
flutter create --platforms=web .
```

Build local para conferir antes de depender do CI:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.vaijunto.app.br/api/v1
```

Saída em `mobile/build/web/`. Em produção esse mesmo comando roda dentro do
`mobile/Dockerfile` (estágio `build`, imagem `ghcr.io/cirruslabs/flutter:3.35.7`
— mesma versão pinada da seção 1 do REQUIREMENTS.md), publicado como
`ghcr.io/vaijunto/vaijunto-web`.

Funcionalidades mobile-only (tracking em background via `geolocator`,
push notifications via `firebase_messaging`) hoje não são importadas por
nenhuma tela alcançável a partir de `main.dart` — não bloqueiam o build web
por não entrarem na compilação. Se/quando forem ligadas a uma tela, cada uma
precisa do próprio tratamento web (permissão de geolocalização do navegador
via HTTPS, config de Firebase Web/VAPID key) — nenhum dos dois está
configurado ainda, então mantenha essas features atrás de um fallback
(`kIsWeb`) até existir esse config.

## 6. Pendências que exigem ação manual (fora do alcance deste repositório)

- Gerar `mobile/web/` (`flutter create --platforms=web .`) e rodar
  `flutter build web --release --dart-define=API_BASE_URL=https://api.vaijunto.app.br/api/v1`
  localmente pelo menos uma vez antes do primeiro deploy, para pegar qualquer
  incompatibilidade de plugin com web cedo (fora do alcance deste ambiente —
  sem Flutter instalado aqui).
- Customizar `mobile/web/manifest.json`, `mobile/web/index.html` e os ícones
  gerados (nome "VaiJunto", cores do tema, ícones do PWA) depois do
  `flutter create` acima — o scaffold gerado vem com os valores default do
  Flutter.
- Adicionar `CORS_ALLOWED_ORIGINS=https://vaijunto.app.br` e
  `WEB_IMAGE=ghcr.io/vaijunto/vaijunto-web:latest` ao `.env` da VPS (seção 2.3).
- Adicionar o serviço `web` e o bloco `vaijunto.app.br` no
  `docker-compose.yml`/Caddyfile reais da VPS (seções 2.1/2.2).
- ~~Aplicar a correção do script de backup (seção 4.3)~~ — **feito em
  2026-08-13**, `/usr/local/bin/backup-vaijunto-db.sh` já roda com
  `pipefail` + checagem de arquivo vazio. Primeiro backup validado sob o
  script novo: `vaijunto_2026-08-13_21-25.sql.gz`. `deploy.sh` já tinha
  sido auditado e não precisou de mudança.
- Confirmar que o crontab do backup redireciona stdout/stderr para um log
  visível, ou plugar um heartbeat externo (seção 4.3) — ainda pendente.
- Recomendado, não bloqueante: em algum momento fazer um *test restore*
  desse `.sql.gz` num banco descartável, só para confirmar que o dump é
  restaurável de ponta a ponta (um backup nunca "vazio" não é a mesma
  garantia que um backup restaurável).
- Confirmar que o `docker-compose.yml` real da VPS bate com a seção 2.1
  (principalmente: `db` sem `ports:` publicado, `backend` só em
  `127.0.0.1:8080`).
- Confirmar que `.env` da VPS define `JWT_SECRET` próprio (não o default
  do `application.yml`).
- Configurar os GitHub Secrets `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY` e o
  environment `production` com o aprovador correto (se ainda não feito).
# CORS do Cloudflare R2

O upload e a leitura direta no PWA exigem CORS no bucket. Aplique uma regra
equivalente à abaixo, trocando a origem pelo domínio publicado (não use `*` em
produção):

```json
[
  {
    "AllowedOrigins": ["https://vaijunto.app.br"],
    "AllowedMethods": ["GET", "HEAD", "PUT"],
    "AllowedHeaders": ["Content-Type", "Content-Length", "x-amz-*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

Valide o bucket em ambiente seguro com
`R2_INTEGRATION_TEST=true mvnw test -Dtest=R2ConnectionIntegrationTest`. O app
só conclui a intenção depois de um `PUT` bem-sucedido e o backend confirma o
objeto com `HEAD` antes de ativá-lo.
