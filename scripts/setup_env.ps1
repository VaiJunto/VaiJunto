# Script de instalacao dos pre-requisitos do VaiJunto no perfil do usuario atual

$ProgressPreference = 'SilentlyContinue'
$UserDev = "$env:USERPROFILE\dev"
$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk"

New-Item -ItemType Directory -Force -Path $UserDev | Out-Null
New-Item -ItemType Directory -Force -Path $AndroidSdk | Out-Null

# 1. Download & Extract Maven 3.9.9
$MavenTarget = "$UserDev\maven\apache-maven-3.9.9\bin\mvn.cmd"
if (-not (Test-Path $MavenTarget)) {
    Write-Host "=> Baixando Maven 3.9.9..." -ForegroundColor Cyan
    $mvnZip = "$env:TEMP\maven.zip"
    Invoke-WebRequest -Uri "https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip" -OutFile $mvnZip
    Expand-Archive -Path $mvnZip -DestinationPath "$UserDev\maven" -Force
    Remove-Item $mvnZip -Force
    Write-Host "   Maven instalado em $UserDev\maven" -ForegroundColor Green
} else {
    Write-Host "   Maven 3.9.9 ja instalado." -ForegroundColor Green
}

# 2. Download & Extract JDK 17 (Temurin)
$JdkTarget = "$UserDev\jdk17\jdk-17.0.13+11"
if (-not (Test-Path $JdkTarget)) {
    Write-Host "=> Baixando JDK 17 (Eclipse Temurin)..." -ForegroundColor Cyan
    $jdkZip = "$env:TEMP\jdk17.zip"
    Invoke-WebRequest -Uri "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_11.zip" -OutFile $jdkZip
    Expand-Archive -Path $jdkZip -DestinationPath "$UserDev\jdk17" -Force
    Remove-Item $jdkZip -Force
    Write-Host "   JDK 17 instalado em $JdkTarget" -ForegroundColor Green
} else {
    Write-Host "   JDK 17 ja instalado." -ForegroundColor Green
}

# 3. Download & Extract Android Platform Tools (adb)
$AdbTarget = "$AndroidSdk\platform-tools\adb.exe"
if (-not (Test-Path $AdbTarget)) {
    Write-Host "=> Baixando Android Platform Tools (adb)..." -ForegroundColor Cyan
    $adbZip = "$env:TEMP\platform-tools.zip"
    Invoke-WebRequest -Uri "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -OutFile $adbZip
    Expand-Archive -Path $adbZip -DestinationPath $AndroidSdk -Force
    Remove-Item $adbZip -Force
    Write-Host "   ADB instalado em $AndroidSdk\platform-tools" -ForegroundColor Green
} else {
    Write-Host "   ADB ja instalado." -ForegroundColor Green
}

Write-Host "`nSetup concluido com sucesso!" -ForegroundColor Green
