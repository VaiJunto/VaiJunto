# Guia Completo: Como Rodar o Projeto VaiJunto

Este documento contém o passo a passo detalhado para configurar, executar e depurar o projeto **VaiJunto** (Backend Spring Boot + App Mobile Flutter + PostgreSQL/PostGIS).

---

## 🚀 Método Rápido (Modo Automático via PowerShell)

O projeto possui um script automatizado [`dev.ps1`](file:///r:/Dev/VaiJunto/dev.ps1) que cuida de subir o banco de dados, iniciar o backend, compilar o app e configurar o túnel `adb`:

### 1. Rodar no Web (Google Chrome) - *Modo mais rápido para testar UI*
```powershell
.\dev.ps1 -Web
```
> Acesse no navegador: **`http://localhost:5555`**

### 2. Rodar no Celular Físico / Emulador Android via USB
```powershell
.\dev.ps1
```

### 3. Rodar conectando ao Banco de Produção via Túnel SSH (`-RemoteDb`)
```powershell
# Antes de rodar, abra o túnel SSH em outro terminal:
# ssh -N -L 5433:127.0.0.1:5432 napo@api.vaijunto.app.br

.\dev.ps1 -Web -RemoteDb
```
> **Segurança:** A flag `-RemoteDb` desativa automaticamente o Flyway (`FLYWAY_ENABLED=false`) para evitar a execução de migrations acidentais no banco de produção.

### 4. Rodar o App ignorando o Backend (caso já esteja rodando em outro terminal)
```powershell
.\dev.ps1 -SkipBackend
# ou para Web:
.\dev.ps1 -Web -SkipBackend
```

---

## 📋 Pré-requisitos e Versões Exatas

> ⚠️ **Atenção:** Utilizar versões mais novas do Flutter ou Java 21 para o Gradle pode quebrar o build devido a incompatibilidades de AGP e plugins. Siga as versões abaixo:

| Ferramenta | Versão Recomendada | Observação |
|---|---|---|
| **Java / JDK** | **JDK 17** (ex: Eclipse Temurin) | Usado para o backend Spring Boot e para o build Gradle do Android. **Não use o Java 21 do Android Studio.** |
| **Flutter SDK** | **3.35.7** | Versão compatível com alinhamento 16KB (Android 15+) e AGP 8.7. |
| **Maven** | **3.9.9** | Para compilar e executar o backend Java. |
| **PostgreSQL** | **18** (Nativo Windows) | Serviço Windows (`postgresql-x64-18`). **Não utilize Docker Desktop neste ambiente.** |
| **PostGIS** | **3.6.2** (bundle `pg18`) | Extensão geoespacial obrigatória para o PostgreSQL. |
| **Android SDK** | API 36, `cmdline-tools;latest` | Necessário para compilar o APK Android. |

---

## ☁️ Conectar ao Banco de Dados na Nuvem

Se você prefere rodar o backend localmente conectando-se a um PostgreSQL/PostGIS hospedado na nuvem (Supabase, Neon, AWS RDS, VPS, Render, etc.), basta definir as variáveis de conexão no arquivo [`backend\.env.local`](file:///r:/Dev/VaiJunto/backend/.env.local):

Adicione as seguintes linhas ao `backend\.env.local`:
```env
DB_HOST=seu-banco-na-nuvem.com  # IP ou Host da nuvem
DB_PORT=5432                   # Porta (ex: 5432 ou 6543)
DB_NAME=vaijunto_db            # Nome do banco de dados na nuvem
DB_USER=vaijunto_user          # Usuário do banco
DB_PASS=sua_senha_do_banco     # Senha do banco
```

Ao rodar `.\dev.ps1`, o script detectará automaticamente que `DB_HOST` não é local e se conectará ao seu banco remoto sem exigir o PostgreSQL instalado localmente no Windows!

---

## 🛠️ Passo a Passo Manual (Setup do Zero)

### Passo 1: Configurar o Banco de Dados (PostgreSQL + PostGIS)

1. Certifique-se de que o serviço do PostgreSQL 18 está rodando no Windows.
2. Abra o terminal do `psql` (ou PGAdmin) com usuário `postgres` e execute:

```sql
CREATE USER vaijunto_user WITH PASSWORD 'vaijunto_password';
CREATE DATABASE vaijunto_db OWNER vaijunto_user;
\c vaijunto_db
CREATE EXTENSION postgis;
```

---

### Passo 2: Configurar Variáveis de Ambiente do Backend (Opcional)

Para o envio de e-mails de confirmação de cadastro (SMTP do Gmail em desenvolvimento):

1. Crie o arquivo `backend\.env.local` (baseado no exemplo `backend\.env.local.example`):
```env
MAIL_USERNAME=seuemail@gmail.com
MAIL_PASSWORD=sua_senha_de_app_gmail
```

---

### Passo 3: Rodar o Backend (Spring Boot)

1. Navegue até a pasta do backend e execute via Maven:
```powershell
cd backend
mvn spring-boot:run
```
2. O servidor iniciará na porta **`8080`**.
3. **Verificação de Healthcheck**:
   Acesse: `http://localhost:8080/actuator/health` (deve retornar `{"status":"UP"}`).

---

### Passo 4: Configurar e Rodar o App Mobile (Flutter)

#### 4.1 Primeira Execução (Gerar pasta `android/` se necessário)
Se a pasta `android/` não existir no diretório `mobile`:
```powershell
cd mobile
flutter create --platforms=android --org com.vaijunto .
flutter pub get
```

#### 4.2 Rodar no Web
```powershell
cd mobile
flutter run -d web-server --web-port=5555
```
Acesse `http://localhost:5555` no navegador.

#### 4.3 Rodar em Dispositivo Android Físico via USB
1. Ative a **Depuração USB** no celular.
2. Conecte o cabo USB e garanta que o dispositivo esteja listado com status `device`:
   ```powershell
   adb devices
   ```
3. **Redirecionar a porta do backend (`adb reverse`)**:
   > ⚠️ **CRÍTICO:** Sempre que o cabo USB é reconectado, o redirecionamento cai. Execute:
   ```powershell
   adb reverse tcp:8080 tcp:8080
   ```
4. Compilar e instalar o app:
   ```powershell
   cd mobile
   flutter build apk --debug
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

---

## ⚠️ Dicas e Soluções de Problemas Frequentes

### 1. `SocketException: Connection refused (127.0.0.1)` no Celular
- **Causa:** O cabo USB foi desconectado/reconectado e o túnel ADB caiu.
- **Solução:** Execute `adb reverse tcp:8080 tcp:8080` (não precisa recompilar nem reinstalar o app).

### 2. Erro de `jlink` / `JdkImageTransform` no build do Android
- **Causa:** O Gradle está tentando usar o Java 21 (JBR do Android Studio).
- **Solução:** No arquivo `mobile/android/gradle.properties`, defina:
  ```properties
  org.gradle.java.home=C:\\caminho\\para\\jdk-17
  ```
  Em seguida, pare os daemons antigos com `gradlew --stop` e tente novamente.

### 3. Regra de Versionamento Obrigatório do App
- **Regra:** Sempre que alterar código que exija recompilar o app físico, incrementa-se a versão simultaneamente em:
  - [`mobile/lib/core/app_version.dart`](file:///r:/Dev/VaiJunto/mobile/lib/core/app_version.dart) (`kAppVersion = '1.0.0.X'`)
  - [`mobile/pubspec.yaml`](file:///r:/Dev/VaiJunto/mobile/pubspec.yaml) (`version: 1.0.0+X`)
  - Veja mais regras no arquivo [`CLAUDE.md`](file:///r:/Dev/VaiJunto/CLAUDE.md).

---

## 📚 Documentações de Referência no Projeto

- [`CLAUDE.md`](file:///r:/Dev/VaiJunto/CLAUDE.md) — Regras de versionamento, neobrutalismo UI e padrões do projeto.
- [`REQUIREMENTS.md`](file:///r:/Dev/VaiJunto/REQUIREMENTS.md) — Detalhes completos do setup do ambiente, versões, Gradle, Postgres/PostGIS.
- [`DOCUMENTATION.md`](file:///r:/Dev/VaiJunto/DOCUMENTATION.md) — Documentação da arquitetura e especificações de software.
