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
    → build da imagem Docker (contexto: backend/, Dockerfile: backend/Dockerfile)
    → push para ghcr.io/vaijunto/vaijunto-backend:latest
                e ghcr.io/vaijunto/vaijunto-backend:sha-<commit>
    → aguarda aprovação do environment "production"
  → (usuário aprova no GitHub)
  → SSH na VPS (secrets VPS_HOST / VPS_USER / VPS_SSH_KEY)
    → executa /opt/apps/vaijunto/deploy.sh
      → docker compose pull
      → docker compose up -d
  → api.vaijunto.app.br atualizada
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
    ports:
      - "127.0.0.1:8080:8080"   # só loopback — Caddy é quem expõe pra internet
```

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

### 2.2 `.env` da VPS — variáveis esperadas

```env
POSTGRES_DB=vaijunto
POSTGRES_USER=vaijunto
POSTGRES_PASSWORD=<secreto>

# ver nota acima — DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASS (recomendado)
# ou SPRING_DATASOURCE_URL/USERNAME/PASSWORD (o que já está em uso)

MAIL_USERNAME=<secreto>
MAIL_PASSWORD=<secreto>
JWT_SECRET=<secreto, gerar um valor forte próprio — não usar o default do application.yml>

BACKEND_IMAGE=ghcr.io/vaijunto/vaijunto-backend:latest
```

⚠️ `jwt.secret` no [application.yml](backend/src/main/resources/application.yml)
tem um valor default hardcoded. Ele só é usado se `JWT_SECRET` não estiver
definido — **confirme que a VPS define `JWT_SECRET` com um valor próprio**,
nunca o default do repositório (esse default vale para dev local).

### 2.3 `deploy.sh` (conteúdo real, confirmado em `/opt/apps/vaijunto/deploy.sh`)

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

### 5.1 Build de produção do app mobile

Não existe `mobile/web/` no repositório — **Flutter Web não é uma plataforma
real deste projeto** (o `-Web` do `dev.ps1` é só `flutter run -d web-server`
para hot reload local; não há build/deploy de web para a VPS). O app é
Android via APK/AAB.

Para apontar um build para produção:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.vaijunto.app.br/api/v1
```

Sem essa flag, o build usa o default de dev (`127.0.0.1:8080`) — build de
release feito sem `--dart-define` **não vai funcionar fora da rede local**.

## 6. Pendências que exigem ação manual (fora do alcance deste repositório)

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
