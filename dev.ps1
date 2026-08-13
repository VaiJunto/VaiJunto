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

.PARAMETER SkipBackend
    Não mexe no backend (útil se você já está com ele rodando em outro terminal).

.EXAMPLE
    .\dev.ps1              # build + instala no device + abre
    .\dev.ps1 -Web         # roda no Chrome com hot reload
#>
param(
    [switch]$Web,
    [switch]$SkipBackend
)

$ErrorActionPreference = "Stop"

$Root       = $PSScriptRoot
$FlutterBin = "C:\Users\Gabriel\dev\flutter\bin"
$Jdk17      = "C:\Users\Gabriel\dev\jdk17\jdk-17.0.13+11"
$Maven      = "C:\Users\Gabriel\dev\maven\apache-maven-3.9.9\bin\mvn.cmd"
$Sdk        = "C:\Users\Gabriel\AppData\Local\Android\Sdk"
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

# Carrega backend\.env.local (MAIL_USERNAME/MAIL_PASSWORD) se existir, para o
# envio de e-mail de confirmação funcionar. Nunca commitado (está no
# .gitignore) — veja backend\.env.local.example para o formato.
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
    Write-Step "Postgres"
    $pg = Get-Service "postgresql-x64-18" -ErrorAction SilentlyContinue
    if (-not $pg) {
        Write-Warn "Servico postgresql-x64-18 nao encontrado. Pulei."
    } elseif ($pg.Status -ne "Running") {
        Start-Service $pg.Name
        Write-Ok "Iniciado."
    } else {
        Write-Ok "Ja rodando."
    }

    # ------------------------------------------------------------- Backend --
    Write-Step "Backend Spring Boot"
    if (Test-Backend) {
        Write-Ok "Ja no ar em :8080."
    } else {
        Import-DotEnv "$Root\backend\.env.local"
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
