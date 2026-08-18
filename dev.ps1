<#
.SYNOPSIS
    Sobe o ambiente de desenvolvimento do VaiJunto de uma vez só.

.DESCRIPTION
    Cuida de tudo que é chato e repetitivo:
      - garante que o Postgres está rodando
      - sobe o backend Spring Boot (se ainda não estiver no ar)
      - compila o app e instala no device conectado (celular ou emulador)
      - refaz o `adb reverse`, que cai toda vez que o cabo é reconectado
      - abre o app no device

.PARAMETER Web
    Em vez de compilar APK, roda no Chrome com hot reload (loop bem mais rápido
    para mexer em UI). Não precisa de celular nem emulador.

.PARAMETER RemoteDb
    Conecta o backend local ao banco de PRODUCAO via tunel SSH (127.0.0.1:5433).
    Desativa automaticamente as migrations do Flyway por seguranca.

.PARAMETER StopBackend
    Finaliza o processo do backend Spring Boot que estiver rodando na porta 8080.

.EXAMPLE
    .\dev.ps1              # build + instala no device + abre
    .\dev.ps1 -Web         # roda no Chrome com hot reload
    .\dev.ps1 -Web -RemoteDb # roda no Chrome conectando ao banco de PRODUCAO
    .\dev.ps1 -StopBackend # para o backend que esta rodando em segundo plano
#>
param(
    [switch]$Web,
    [switch]$SkipBackend,
    [switch]$RemoteDb,
    [switch]$StopBackend
)

$ErrorActionPreference = "Stop"

$Root       = $PSScriptRoot
$UserDev    = "$env:USERPROFILE\dev"

if ($StopBackend) {
    Write-Host "=> Parando o backend..." -ForegroundColor Cyan
    $pids = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($pids) {
        foreach ($p in $pids) {
            Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
        }
        Write-Host "   Backend parado com sucesso!" -ForegroundColor Green
    } else {
        Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "   Nenhum processo escutando na porta 8080." -ForegroundColor Yellow
    }
    return
}

# Busca dinâmica das ferramentas no perfil do usuário atual, PATH ou fallback Gabriel
$FlutterBin = if (Test-Path "$UserDev\flutter\bin") { "$UserDev\flutter\bin" } elseif (Get-Command flutter -ErrorAction SilentlyContinue) { Split-Path (Get-Command flutter).Source } else { "$UserDev\flutter\bin" }
$Jdk17      = if (Test-Path "$UserDev\jdk17\jdk-17.0.13+11") { "$UserDev\jdk17\jdk-17.0.13+11" } elseif (Test-Path "$UserDev\jdk17") { "$UserDev\jdk17" } else { "$UserDev\jdk17" }
$Maven      = if (Test-Path "$UserDev\maven\apache-maven-3.9.9\bin\mvn.cmd") { "$UserDev\maven\apache-maven-3.9.9\bin\mvn.cmd" } elseif (Test-Path "$UserDev\maven\bin\mvn.cmd") { "$UserDev\maven\bin\mvn.cmd" } elseif (Get-Command mvn -ErrorAction SilentlyContinue) { (Get-Command mvn).Source } else { "$UserDev\maven\apache-maven-3.9.9\bin\mvn.cmd" }
$Sdk        = if (Test-Path "$env:LOCALAPPDATA\Android\Sdk") { "$env:LOCALAPPDATA\Android\Sdk" } else { "C:\Users\Gabriel\AppData\Local\Android\Sdk" }
$Adb        = "$Sdk\platform-tools\adb.exe"
$AppId      = "com.vaijunto.mobile"

$env:JAVA_HOME        = $Jdk17
$env:ANDROID_SDK_ROOT = $Sdk
$env:PATH             = "$FlutterBin;$Sdk\platform-tools;$Jdk17\bin;$env:PATH"

function Write-Step($msg) { Write-Host "`n=> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "   $msg" -ForegroundColor Yellow }

function Test-Backend {
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -TimeoutSec 3
        return $r.status -eq "UP"
    } catch { return $false }
}

function Test-PortOpen($targetHost, $targetPort) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $client.BeginConnect($targetHost, $targetPort, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(1000, $false)
        if (-not $wait) {
            $client.Close()
            return $false
        }
        $client.EndConnect($asyncResult)
        $client.Close()
        return $true
    } catch { return $false }
}

# Carrega arquivo .env no ambiente atual
function Import-DotEnv($path) {
    if (-not (Test-Path $path)) { return }
    Get-Content $path | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)\s*=\s*(.*)\s*$') {
            $name, $value = $matches[1].Trim(), $matches[2].Trim()
            if ($value) { Set-Item -Path "env:$name" -Value $value }
        }
    }
}

# ---------------------------------------------------------------- Postgres --
if (-not $SkipBackend) {
    Import-DotEnv "$Root\backend\.env.local"

    if ($RemoteDb) {
        Write-Step "Postgres (PRODUCAO)"

        # Carrega credenciais remotas se existirem
        Import-DotEnv "$Root\backend\.env.remote"

        # Defaults de credenciais do tunel SSH se nao definidos no .env.remote
        if (-not $env:DB_HOST) { $env:DB_HOST = "127.0.0.1" }
        if (-not $env:DB_PORT) { $env:DB_PORT = "5433" }
        if (-not $env:DB_NAME) { $env:DB_NAME = "vaijunto" }
        if (-not $env:DB_USER) { $env:DB_USER = "vaijunto" }
        if (-not $env:DB_PASS) { $env:DB_PASS = "fV5n7VOsZe8RToakyOrjxdbQ09X3LymsE4WvkNwxJLM=" }

        # Trava obrigatoria de seguranca: desativa Flyway para nao aplicar migrations em producao
        $env:FLYWAY_ENABLED = "false"
        $env:SPRING_FLYWAY_ENABLED = "false"

        # Checa se o tunel SSH (127.0.0.1:5433) esta ativo
        $tunnelPort = [int]$env:DB_PORT
        if (-not (Test-PortOpen "127.0.0.1" $tunnelPort)) {
            Write-Host "   [ERRO] Tunel SSH nao encontrado na porta $tunnelPort!" -ForegroundColor Red
            Write-Host "   Abra o tunel SSH em outro terminal executando:" -ForegroundColor Yellow
            Write-Host "   ssh -N -L 5433:127.0.0.1:5432 napo@api.vaijunto.app.br" -ForegroundColor Cyan
            throw "Tunel SSH para producao nao esta ativo na porta $tunnelPort."
        }

        Write-Host "   !!! ATENCAO: CONECTADO AO BANCO DE PRODUCAO !!!" -ForegroundColor Red
        Write-Ok "Tunel SSH detectado na porta $tunnelPort."
        Write-Ok "Flyway desativado (migrations bloqueadas)."
    } elseif (-not $env:DB_HOST -or $env:DB_HOST -eq "localhost" -or $env:DB_HOST -eq "127.0.0.1") {
        Write-Step "Postgres (Local)"
        $pg = Get-Service "postgresql-x64-18" -ErrorAction SilentlyContinue
        if (-not $pg) {
            Write-Warn "Servico postgresql-x64-18 nao encontrado. Pulei."
        } elseif ($pg.Status -ne "Running") {
            Start-Service $pg.Name
            Write-Ok "Iniciado."
        } else {
            Write-Ok "Ja rodando."
        }
    } else {
        Write-Step "Postgres (Nuvem)"
        Write-Ok "Conectando ao banco em: $env:DB_HOST"
    }

    # ------------------------------------------------------------- Backend --
    Write-Step "Backend Spring Boot"
    if (Test-Backend) {
        Write-Ok "Ja no ar em :8080."
    } else {
        if (-not $env:MAIL_USERNAME) {
            Write-Warn "MAIL_USERNAME nao configurado (backend\.env.local) - envio de e-mail vai falhar silenciosamente."
        }
        Write-Warn "Subindo (log: backend-dev.log)..."
        Start-Process -FilePath $Maven `
            -ArgumentList "-q", "spring-boot:run" `
            -WorkingDirectory "$Root\backend" `
            -RedirectStandardOutput "$Root\backend-dev.log" `
            -RedirectStandardError "$Root\backend-dev.err.log" `
            -WindowStyle Hidden

        $waited = 0
        while (-not (Test-Backend) -and $waited -lt 120) {
            Start-Sleep -Seconds 3
            $waited += 3
            Write-Host "." -NoNewline
        }
        Write-Host ""
        if (Test-Backend) { Write-Ok "No ar em :8080." }
        else { throw "Backend nao subiu em ${waited}s. Veja backend-dev.log" }
    }
}

# --------------------------------------------------------------------- App --
Push-Location "$Root\mobile"
try {
    if ($Web) {
        Write-Step "Servidor web (hot reload: tecle 'r' | sair: 'q')"
        Write-Warn "Nao abre navegador sozinho - acesse http://localhost:5555 na aba que voce ja tiver aberta."
        flutter run -d web-server --web-port=5555
        return
    }

    Write-Step "Device"
    $devices = & $Adb devices | Select-String -Pattern "\tdevice$"
    if (-not $devices) {
        throw "Nenhum device conectado. Ligue o celular via USB (com depuracao USB) ou inicie um emulador."
    }
    Write-Ok ($devices -join ", ").Trim()

    Write-Step "Compilando APK debug"
    flutter build apk --debug
    if ($LASTEXITCODE -ne 0) { throw "Build falhou." }
    Write-Ok "OK."

    Write-Step "Instalando"
    & $Adb install -r "build\app\outputs\flutter-apk\app-debug.apk" | Out-Null
    Write-Ok "Instalado."

    # Cai sempre que o cabo é reconectado — por isso refazemos incondicionalmente.
    Write-Step "Tunel adb reverse :8080"
    & $Adb reverse tcp:8080 tcp:8080 | Out-Null
    Write-Ok (& $Adb reverse --list)

    Write-Step "Abrindo o app"
    & $Adb shell monkey -p $AppId -c android.intent.category.LAUNCHER 1 | Out-Null
    Write-Ok "Pronto."
}
finally {
    Pop-Location
}
