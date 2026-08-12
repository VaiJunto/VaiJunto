# REQUIREMENTS — Setup do Ambiente (VaiJunto)

> Este arquivo documenta **tudo que é preciso instalar e configurar** para compilar o app mobile
> e rodar o backend localmente neste projeto, incluindo as pegadinhas específicas encontradas
> durante o primeiro setup (2026-08-12). Leia antes de tentar rodar o projeto do zero —
> várias combinações "óbvias" de versões (Flutter mais novo, Java 21, etc.) **quebram o build**.

## Visão geral do stack

- **Mobile**: Flutter (Android). Código em `mobile/lib`. As pastas `mobile/android`, `mobile/.dart_tool`,
  `mobile/pubspec.lock` **não são versionadas no git** — são geradas localmente.
- **Backend**: Spring Boot 3.2.3 / Java 17, Maven (`backend/pom.xml`). Sem `mvnw` commitado.
- **Banco**: PostgreSQL 16 + PostGIS, via Docker (`docker-compose.yml` na raiz).
- **Comunicação app ↔ backend em device físico via USB**: `adb reverse tcp:8080 tcp:8080`
  (o app fala com `localhost:8080` no celular, que é redirecionado pro `localhost:8080` do PC).

---

## 1. Pré-requisitos exatos (não use "a versão mais nova")

| Ferramenta | Versão usada | Onde/Como | Por quê |
|---|---|---|---|
| Flutter SDK | **3.24.5 (stable)** | `git checkout 3.24.5` dentro do clone do Flutter | Flutter 3.29+/AGP 9 quebra plugins antigos (geolocator, google_maps_flutter) que ainda usam Groovy DSL — ver seção 4. |
| JDK para o **Gradle** (build do app Android) | **JDK 17** (Eclipse Temurin) | baixar à parte, NÃO usar o JBR do Android Studio | O JBR do Android Studio é Java 21, que tem bug de `jlink` incompatível com módulos Android antigos (erro `JdkImageTransform`/`core-for-system-modules.jar`). Ver seção 4. |
| JDK para o **backend** | Java 17 | mesmo JDK 17 acima serve | `pom.xml` exige `java.version=17`. |
| Android SDK | API 36 instalada (`platforms/android-36`), `cmdline-tools;latest`, `build-tools` | `C:\Users\<user>\AppData\Local\Android\Sdk` (ou onde o Android Studio instalou) | `cmdline-tools` não vem por padrão — precisa baixar/instalar separado pra rodar `sdkmanager --licenses`. |
| Maven | 3.9.9 | baixar zip de `https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip` (o link `dlcdn.apache.org` pode dar 404 pra versões antigas — use o archive) | Projeto não tem `mvnw`. |
| Docker Desktop | qualquer versão recente | precisa estar **rodando** (não só instalado) antes de `docker-compose up` | Sobe o Postgres/PostGIS local. Ver bug conhecido na seção 5. |

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
    minSdkVersion: 23,
    targetSdkVersion: 36,
]
```

### 4.2 `android/app/build.gradle` — versões explícitas

```groovy
android {
    compileSdk = 36        // só a platform 36 está instalada no SDK
    ...
    defaultConfig {
        minSdk = 23          // geolocator_android exige minSdk >= 23
        targetSdk = 36
        ...
    }
}
```

### 4.3 `android/gradle/wrapper/gradle-wrapper.properties`

Trocar `gradle-8.3-all.zip` (padrão do template) por **`gradle-8.7-all.zip`** — o Gradle 8.3
não é compatível com Java 17/21 usados aqui.

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

```bash
docker-compose up -d          # sobe o Postgres/PostGIS na raiz do projeto
cd backend
mvn spring-boot:run           # ou: mvn clean package && java -jar target/*.jar
```

Config de conexão em `backend/src/main/resources/application.yml` (usa env vars com
defaults: `DB_HOST=localhost`, `DB_NAME=vaijunto_db`, `DB_USER=vaijunto_user`,
`DB_PASS=vaijunto_password` — bate com o `docker-compose.yml`).

### ⚠️ Bug conhecido: Docker Desktop não inicia (Windows)

Se o Docker Desktop crashar ao abrir com erro tipo:

```
starting services: initializing Inference manager / Secrets Engine: listening on
unix://...: remove ...: Não é possível o acesso ao arquivo pelo sistema.
```

Isso é um socket AF_UNIX (reparse point) que ficou travado de um fechamento anormal anterior.
Sintomas: nem `Remove-Item -Force`, nem `cmd /c del`, nem `fsutil reparsepoint delete`
conseguem apagar o arquivo, mesmo com todos os processos do Docker parados.

**Fix confiável: reiniciar o Windows.** O lock é a nível de kernel/driver e só libera no reboot.
(Tentativas de apagar manualmente os arquivos em `%LOCALAPPDATA%\Docker\run\` e
`%LOCALAPPDATA%\docker-secrets-engine\` antes de reiniciar podem ajudar, mas não resolveram
sozinhas neste ambiente.)

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
