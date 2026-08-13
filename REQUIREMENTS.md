# REQUIREMENTS — Setup do Ambiente (VaiJunto)

> Este arquivo documenta **tudo que é preciso instalar e configurar** para compilar o app mobile
> e rodar o backend localmente neste projeto, incluindo as pegadinhas específicas encontradas
> durante o primeiro setup (2026-08-12). Leia antes de tentar rodar o projeto do zero —
> várias combinações "óbvias" de versões (Flutter mais novo, Java 21, etc.) **quebram o build**.

## Visão geral do stack

- **Mobile**: Flutter (Android). Código em `mobile/lib`. As pastas `mobile/android`, `mobile/.dart_tool`,
  `mobile/pubspec.lock` **não são versionadas no git** — são geradas localmente.
- **Backend**: Spring Boot 3.2.3 / Java 17, Maven (`backend/pom.xml`). Sem `mvnw` commitado.
- **Banco**: PostgreSQL + PostGIS. **Instalado nativamente no Windows, NÃO via Docker** — o
  `docker-compose.yml` da raiz existe mas o Docker Desktop não inicia neste ambiente (ver 5.4).
- **Comunicação app ↔ backend em device físico via USB**: `adb reverse tcp:8080 tcp:8080`
  (o app fala com `localhost:8080` no celular, que é redirecionado pro `localhost:8080` do PC).

---

## 1. Pré-requisitos exatos (não use "a versão mais nova")

| Ferramenta | Versão usada | Onde/Como | Por quê |
|---|---|---|---|
| Flutter SDK | **3.35.7** | `git checkout 3.35.7` dentro do clone do Flutter | Sweet spot: tem alinhamento de 16KB (exigido pelo Android 15+) e ainda usa AGP 8.x. **Não use 3.47+** — ele adota AGP 9, que só lê o novo DSL e quebra plugins Groovy (geolocator, google_maps_flutter). **Não use 3.24.5** — não tem 16KB e não roda geolocator 14 (`Color.toARGB32()` não existe). |
| JDK para o **Gradle** (build do app Android) | **JDK 17** (Eclipse Temurin) | baixar à parte, NÃO usar o JBR do Android Studio | O JBR do Android Studio é Java 21, que tem bug de `jlink` incompatível com módulos Android antigos (erro `JdkImageTransform`/`core-for-system-modules.jar`). Ver seção 4. |
| JDK para o **backend** | Java 17 | mesmo JDK 17 acima serve | `pom.xml` exige `java.version=17`. |
| Android SDK | API 36 instalada (`platforms/android-36`), `cmdline-tools;latest`, `build-tools` | `C:\Users\<user>\AppData\Local\Android\Sdk` (ou onde o Android Studio instalou) | `cmdline-tools` não vem por padrão — precisa baixar/instalar separado pra rodar `sdkmanager --licenses`. |
| Maven | 3.9.9 | baixar zip de `https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip` (o link `dlcdn.apache.org` pode dar 404 pra versões antigas — use o archive) | Projeto não tem `mvnw`. |
| PostgreSQL | **18** (nativo Windows, serviço `postgresql-x64-18`) | `C:\Program Files\PostgreSQL\18` | Banco da aplicação. Ver 5.1. |
| PostGIS | **3.6.2** (bundle `pg18`) | copiado manualmente por cima da instalação do Postgres | Extensão geoespacial — o backend não sobe sem ela. Não vem no instalador do Postgres. Ver 5.1. |
| Docker Desktop | ~~necessário~~ **não use** | — | Não inicia neste ambiente (bug de socket travado). Substituído pelo Postgres nativo. Ver 5.4. |

---

## 2. Setup do celular físico (Android) via ADB

1. Ativar **Opções do desenvolvedor** no celular e ligar **Depuração USB**.
2. Conectar o cabo USB, e mudar o modo de conexão USB (notificação do Android) para
   **"Transferência de arquivos (MTP)"** — no modo "Somente carregamento" o popup de
   autorização às vezes não aparece.
3. Rodar `adb devices` — se aparecer `unauthorized`, **desbloquear a tela do celular** e
   olhar se apareceu o popup "Permitir depuração USB?". Se não aparecer:
   - `adb kill-server && adb start-server`
   - Desconectar/reconectar o cabo com a tela desbloqueada.
   - Em último caso: Ajustes → Opções do desenvolvedor → "Revogar autorizações de depuração USB",
     reconectar e tentar de novo.
4. Quando aparecer `device` (não `unauthorized`) no `adb devices`, está pronto.

---

## 3. Gerando e compilando o app mobile (primeira vez)

O projeto **não tem a pasta `android/` commitada**. Ela precisa ser gerada:

```bash
cd mobile
flutter create --platforms=android --org com.vaijunto .
```

Isso recria `android/build.gradle`, `android/app/build.gradle`, `android/gradle.properties`, etc.
**Depois de gerar, é preciso reaplicar os ajustes da seção 4** (eles não sobrevivem a um
`flutter create` novo).

Depois:

```bash
flutter pub get
flutter build apk --debug
```

APK gerado em `mobile/build/app/outputs/flutter-apk/app-debug.apk`.

Instalar no celular:

```bash
adb install -r mobile/build/app/outputs/flutter-apk/app-debug.apk
adb reverse tcp:8080 tcp:8080
```

### ⚠️ `adb reverse` cai sozinho — reconferir sempre

O redirecionamento **se perde** quando o cabo USB é desconectado/reconectado, quando o
`adb kill-server`/`start-server` roda, ou quando o PC reinicia. Quando isso acontece o app
mostra `SocketException: Connection refused (address = 127.0.0.1)` na tela de login/cadastro —
o que parece bug do app, mas é só o túnel caído.

Antes de culpar o código, confira:

```bash
adb reverse --list      # tem que listar: UsbFfs tcp:8080 tcp:8080
```

Se estiver vazio, basta rodar `adb reverse tcp:8080 tcp:8080` de novo — **não precisa
recompilar nem reinstalar o app**.

---

## 3.1 `dev.ps1 -Web` rodado por um agente/automação (sem terminal interativo)

`flutter run` é interativo por natureza (REPL com `r`/`R`/`q` para hot
reload/restart/quit) — ele espera um stdin de verdade. Se for iniciado por uma
ferramenta que executa o comando com stdin fechado/nulo (ex.: um agente de IA, um
processo automatizado, `& { ... } | Out-Null`), o Flutter recebe EOF no stdin e
**interpreta isso como o comando `q`**: o processo termina sozinho segundos depois
de conectar, mesmo sem erro (`Application finished.`, exit code 0) — parece que
subiu certinho, mas já morreu.

**Sintoma**: `dev.ps1 -Web` parece rodar limpo no log, mas a porta `5555` para de
responder pouco depois.

**Correção**: iniciar o processo destacado do stdin do chamador, do mesmo jeito que
o próprio `dev.ps1` já faz para o backend (`Start-Process` com
`-RedirectStandardOutput`/`-RedirectStandardError`).

**⚠️ Usar `-d web-server`, nunca `-d chrome`, quando quem sobe o processo é um
agente/automação**: `-d chrome` faz o próprio Flutter abrir (e depois controlar) uma
janela de Chrome dedicada. Toda vez que o agente reinicia o processo — porque
mudou código Dart e não há hot reload disponível sem stdin interativo — isso abre
**uma janela de Chrome nova**, o que é incômodo quando quem está testando já tem
uma aba própria aberta. `-d web-server` sobe só o servidor HTTP, sem tocar em
nenhum navegador; quem estiver testando abre `http://localhost:5555` na aba que
já tiver e só dá **F5** depois que o agente avisar que reiniciou. `dev.ps1 -Web`
já usa `-d web-server` por causa disso — não reverter para `-d chrome`.

```powershell
$FlutterBin = "C:\Users\Gabriel\dev\flutter\bin"
$Jdk17      = "C:\Users\Gabriel\dev\jdk17\jdk-17.0.13+11"
$Sdk        = "C:\Users\Gabriel\AppData\Local\Android\Sdk"
$env:JAVA_HOME        = $Jdk17
$env:ANDROID_SDK_ROOT = $Sdk
$env:PATH             = "$FlutterBin;$Sdk\platform-tools;$Jdk17\bin;$env:PATH"

Set-Location "C:\Users\Gabriel\Desktop\VaiJunto\mobile"
Start-Process -FilePath "flutter" -ArgumentList "run","-d","web-server","--web-port=5555" `
    -RedirectStandardOutput "C:\Users\Gabriel\Desktop\VaiJunto\flutter-web-dev.log" `
    -RedirectStandardError  "C:\Users\Gabriel\Desktop\VaiJunto\flutter-web-dev.err.log" `
    -WindowStyle Hidden
```

Assim o processo some do stdin do terminal que disparou o comando e continua vivo,
sem abrir nada na tela de quem está testando. Verificar se está de pé com
`netstat -ano | findstr :5555` (deve ter uma linha `LISTENING`) ou
`curl http://127.0.0.1:5555` (ou `http://[::1]:5555` — o `flutter run --web-port`
só escuta em IPv6 `::1`, não em `127.0.0.1`; se o `curl` IPv4 falhar mas o IPv6
responder 200, está tudo certo).

Como não há aba própria do Flutter conectada via debug service (DWDS) nesse modo,
não existe o risco de matar o processo recarregando a página — qualquer aba
apontando pra porta 5555 pode ser recarregada livremente.

Rodando manualmente num terminal interativo normal (o caso comum, sem automação),
nada disso importa — tanto `-d chrome` quanto `-d web-server` funcionam direto.

---

## 4. Ajustes obrigatórios no Gradle (não removê-los)

### 4.1 `android/build.gradle` — shim de compatibilidade do `flutter.*`

O novo formato de `settings.gradle` do Flutter (desde ~3.24) cria a extensão `flutter`
(com `compileSdkVersion`, `minSdkVersion`, etc.) **só no módulo `:app`**. Plugins antigos como
`geolocator_android` referenciam `flutter.compileSdkVersion` no próprio `build.gradle` deles,
e isso quebra com `Could not get unknown property 'flutter' for extension 'android'`.

Adicionar em `android/build.gradle` (fora do bloco `allprojects`):

```groovy
ext.flutter = [
    compileSdkVersion: 36,
    minSdkVersion: 24,
    targetSdkVersion: 36,
]
```

### 4.2 `android/app/build.gradle` — versões explícitas

```groovy
android {
    compileSdk = 36        // só a platform 36 está instalada no SDK

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17   // Java 8 é obsoleto no AGP 8.7
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17 }

    defaultConfig {
        minSdk = 24
        targetSdk = 36
        ...
    }
}
```

### 4.3 Matriz de versões da toolchain Android (mexer em uma quebra as outras)

| Onde | Valor | Restrição |
|---|---|---|
| `gradle-wrapper.properties` | `gradle-8.9-all.zip` | AGP 8.7 exige Gradle ≥ 8.9. |
| `settings.gradle` → `com.android.application` | `8.7.0` | Flutter 3.35 exige AGP ≥ 8.1.1. |
| `settings.gradle` → `org.jetbrains.kotlin.android` | `2.2.0` | Plugins atuais (`package_info_plus` etc.) vêm compilados com metadata Kotlin 2.2 — Kotlin 1.9 falha com *"Incompatible classes were found in dependencies"*. |
| `app/build.gradle` → `compileOptions`/`jvmTarget` | `VERSION_17` | AGP 8.7 marca Java 8 como obsoleto. |

### 4.4 `android/gradle.properties` — forçar Java 17 no Gradle

O JBR (Java 21) do Android Studio quebra o build com erro de `jlink`/`androidJdkImage`.
Depois de instalar um JDK 17 à parte, forçar:

```properties
org.gradle.java.home=C:\\caminho\\para\\jdk-17.x.x
```

⚠️ Depois de mudar isso, **rodar `gradlew --stop`** (para os daemons antigos do Gradle) antes
do próximo build — senão o Gradle reusa um daemon já iniciado com Java 21.

### 4.5 Licenças do Android SDK

`cmdline-tools` não vem por padrão. Baixar de
`https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip`,
extrair em `<Android SDK>/cmdline-tools/latest/`, e rodar (com `JAVA_HOME` apontando pro
JBR do Android Studio ou outro JDK):

```bash
sdkmanager --licenses --sdk_root="<Android SDK>"
```

---

## 5. Backend (Spring Boot + Postgres)

### 5.1 Banco de dados — PostgreSQL nativo (NÃO use o Docker)

O `docker-compose.yml` da raiz existe e sobe um `postgis/postgis:16-3.4`, **mas neste ambiente
o Docker Desktop não inicia** (ver 5.4). A configuração que efetivamente funciona é
**PostgreSQL instalado nativamente no Windows + PostGIS adicionado por cima**:

1. PostgreSQL 18 instalado em `C:\Program Files\PostgreSQL\18`, rodando como serviço
   `postgresql-x64-18` (sobe sozinho no boot).
2. PostGIS **não vem** com o instalador — baixar o bundle correspondente à versão do Postgres em
   `https://download.osgeo.org/postgis/windows/pg18/` (usado: `postgis-bundle-pg18-3.6.2x64.zip`).
   Instalar = **parar o serviço**, copiar `bin/`, `lib/` e `share/` do bundle por cima de
   `C:\Program Files\PostgreSQL\18\`, e religar o serviço. (Sem parar o serviço, algumas DLLs
   ficam travadas e a cópia falha pela metade.)
3. Criar usuário/banco/extensão (roda com a senha do superusuário `postgres`):

```bash
psql -U postgres -c "CREATE USER vaijunto_user WITH PASSWORD 'vaijunto_password';"
psql -U postgres -c "CREATE DATABASE vaijunto_db OWNER vaijunto_user;"
psql -U postgres -d vaijunto_db -c "CREATE EXTENSION postgis;"
```

Config de conexão em `backend/src/main/resources/application.yml` (env vars com defaults:
`DB_HOST=localhost`, `DB_PORT=5432`, `DB_NAME=vaijunto_db`, `DB_USER=vaijunto_user`,
`DB_PASS=vaijunto_password`).

### 5.2 Rodar o backend

```bash
cd backend
mvn spring-boot:run
```

Sobe na porta 8080. Verificar: `curl http://localhost:8080/actuator/health` → `{"status":"UP"}`.

Testar cadastro ponta a ponta:

```bash
curl -X POST http://localhost:8080/api/v1/auth/register -H "Content-Type: application/json" \
  -d '{"name":"Teste","email":"teste@vaijunto.com","password":"senha123","profileTypes":["PASSENGER"]}'
```

Deve retornar um JWT + o objeto do usuário.

### 5.3 Correções aplicadas no backend (não reverter)

Dois bugs impediam o backend de subir — nenhum deles tinha sido pego porque o backend
nunca havia sido executado:

1. **`application.yml`**: `database-platform` apontava para
   `org.hibernate.spatial.dialect.postgis.PostgisDialect`, classe que **não existe mais** no
   Hibernate 6 (usado pelo Spring Boot 3.2). No Hibernate 6 o suporte espacial é contribuído ao
   dialeto padrão. Correto: `org.hibernate.dialect.PostgreSQLDialect`.
2. **`V1__initial_schema.sql`**: a coluna `users.profile_types` era `VARCHAR(50)[]` (array
   Postgres), mas o `ProfileTypeSetConverter` grava/lê uma **string única separada por vírgula**.
   Com `ddl-auto: validate`, isso derruba o boot com
   `wrong column type ... found [_varchar (Types#ARRAY)], but expecting [varchar(255)]`.
   Alterado para `VARCHAR(255) NOT NULL DEFAULT 'PASSENGER'`, alinhando o schema ao que o
   converter realmente faz. Nenhuma query usa semântica de array nessa coluna, então nada se perde.
   ⚠️ A `DOCUMENTATION.md` ainda descreve essa coluna como array — está desatualizada nesse ponto.

   **Se você alterar uma migration já aplicada**, o Flyway vai reclamar de checksum. Como o banco
   de dev não tem dados, o caminho é recriar: `DROP DATABASE vaijunto_db;` → `CREATE DATABASE ...`
   → `CREATE EXTENSION postgis;` → subir o backend de novo.

### 5.4 E-mail de confirmação de cadastro (SMTP)

O fluxo de cadastro exige confirmar um código de 6 dígitos enviado por e-mail antes de liberar
o login (`email_verified` em `users`). Fase de testes: SMTP do Gmail.

1. Ativar verificação em duas etapas na conta Google usada para enviar.
2. Gerar uma **senha de app** em `https://myaccount.google.com/apppasswords` (não é a senha
   normal da conta — o Gmail bloqueia SMTP de app com a senha normal).
3. Copiar `backend/.env.local.example` para `backend/.env.local` e preencher:

```
MAIL_USERNAME=seuemail@gmail.com
MAIL_PASSWORD=<senha de app gerada>
```

`.env.local` está no `.gitignore` — nunca é commitado. `dev.ps1` carrega esse arquivo sozinho
antes de subir o backend. Rodando `mvn spring-boot:run` direto (sem `dev.ps1`), exportar as
variáveis manualmente antes.

Sem essas variáveis o backend sobe normalmente, mas o envio de e-mail falha silenciosamente
(só loga erro) — o cadastro continua funcionando, só que ninguém recebe o código.

⚠️ **Para produção**: Gmail tem limite de 500 e-mails/dia e domínios `@gov.br` (Fatec/CPS) têm
filtro anti-spam rígido — remetente `@gmail.com` corre risco real de cair em spam ou ser
rejeitado num volume maior. O caminho correto é domínio próprio (`vaijunto.com.br`) + provedor
transacional (Resend, Brevo, MailerSend) com SPF+DKIM+DMARC configurados. **Não montar servidor
de e-mail próprio numa VPS** — IP novo sem reputação é o pior cenário possível para entregar em
`gov.br`. Trocar de provedor depois é só mudar `spring.mail.*` no `application.yml` — nada no
código muda.

### 5.5 ⚠️ Docker Desktop não inicia neste ambiente (não perca tempo)

O Docker Desktop crasha na inicialização com:

```
starting services: initializing Inference manager: listening on
unix://C:/Users/<user>/AppData/Local/Docker/run/dockerInference: remove ...:
Não é possível o acesso ao arquivo pelo sistema.
```

(o mesmo acontece com `docker-secrets-engine\engine.sock`.)

São sockets AF_UNIX (reparse points) travados. **Tentativas que NÃO funcionaram** — não repita:
`Remove-Item -Force`, `cmd /c del /f`, `cmd /c rmdir /s /q`, `fsutil reparsepoint delete`,
`takeown`/`icacls`, matar todos os processos `docker*` antes de apagar, desativar
`"EnableDockerAI": false` em `%APPDATA%\Docker\settings-store.json`, e **reiniciar o Windows**
(o erro voltou igual após o reboot). Controlled Folder Access estava desativado, então não era isso.

**Conclusão: use o Postgres nativo (5.1).** O Docker não é necessário — ele só serviria para
rodar o banco. Se quiser insistir, o próximo passo não testado seria
"Troubleshoot → Reset to factory defaults" ou reinstalar o Docker Desktop.

---

## 6. Estado atual do código mobile (o que funciona e o que não)

- `main.dart` → `HomeScreen` com botões "Entrar" / "Criar conta" navegando para
  `LoginScreen` / `RegisterScreen` (auth feature). **Isso já foi corrigido** — o código original
  tinha bugs que nunca tinham sido pegos porque nada importava essas telas:
  - `auth_provider.dart`, `demand_provider.dart`, `offer_provider.dart`, `trip_provider.dart`
    tinham imports relativos errados (`../data/...` em vez de `../../data/...` — a pasta `data/`
    é irmã de `presentation/`, não filha dela).
  - `login_screen.dart` e `register_screen.dart` usavam `Size.infinity` (não existe) em vez de
    `Size.fromHeight(48)`.
- **Ainda quebrado / não usado**: `lib/features/tracking/data/services/stomp_client_service.dart`
  referencia `package:stomp_dart_client/stomp_dart_client.dart` mas a API do pacote instalado
  não bate (`StompClient`, `StompConfig`, `StompFrame` não resolvem). Como nada importa esse
  arquivo ainda, não quebra o build — mas vai quebrar assim que alguém conectar o tracking em
  tempo real. Precisa revisar a versão do `stomp_dart_client` no `pubspec.yaml` (`^1.0.1`) contra
  a API real do pacote.
- `test/widget_test.dart` (gerado pelo `flutter create`) está quebrado (`MyApp` não existe,
  deveria ser `VaiJuntoApp`) — não afeta o build do app, só quebraria `flutter test`.
- Aviso de "Compatibilidade de apps Android" (alinhamento de 16KB) ao abrir o APK debug no
  celular: **cosmético**, específico de builds debug em Android 15+, não impede o app de rodar.
  Corrigir "de verdade" exigiria migrar para Flutter mais novo + AGP 9, o que quebra o
  `geolocator`/`google_maps_flutter` atuais (ver seção 4) — não vale a pena para uso em debug.

---

## 7. Dependências do `pubspec.yaml` — não atualizar sem motivo

Mantidas nas versões originais do projeto (não as mais recentes do pub.dev):

```yaml
geolocator: ^11.0.0
firebase_core: ^2.27.0
firebase_messaging: ^14.7.19
```

Testado: subir `geolocator` para `^14.0.0` força `geolocator_web ^4.1.1` (exige `web ^1.0.0`),
que conflita com a cadeia de dependências do `firebase_core`/`firebase_messaging` nessas
versões — e mesmo resolvendo o conflito subindo o firebase junto, o `geolocator_android` 5.x
usa `Color.toARGB32()`, uma API que só existe em Flutter mais novo que 3.24.5. Ou seja: para
subir o geolocator seria necessário subir o Flutter inteiro, o que cai no problema da seção 4
(AGP 9 quebra outros plugins). Ciclo conhecido — não vale tentar de novo sem resolver o
ecossistema de plugins como um todo.
