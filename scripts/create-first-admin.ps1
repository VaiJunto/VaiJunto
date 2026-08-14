<#
.SYNOPSIS
  Cria, por acesso direto de desenvolvedor, a primeira conta administrativa.

.DESCRIPTION
  Não há endpoint público de bootstrap: a primeira conta só pode ser criada por
  quem tem acesso ao banco. Execute após o backend aplicar a migration V4.
  A senha é solicitada de forma oculta e gravada como BCrypt pelo PostgreSQL.
#>
param(
    [string]$Email = 'gfreiregomes@gmail.com',
    [string]$Database = 'vaijunto_db',
    [string]$DatabaseUser = 'vaijunto_user',
    [string]$DatabaseHost = 'localhost',
    [int]$DatabasePort = 5432
)

$ErrorActionPreference = 'Stop'
$Psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
if (-not (Test-Path $Psql)) { throw "psql não encontrado em $Psql." }

$password = Read-Host 'Senha do administrador (mínimo de 12 caracteres)' -AsSecureString
$passwordConfirm = Read-Host 'Repita a senha' -AsSecureString
$toPlainText = {
    param([Security.SecureString]$secure)
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}
$plainPassword = & $toPlainText $password
$plainConfirm = & $toPlainText $passwordConfirm
if ($plainPassword.Length -lt 12) { throw 'A senha precisa ter ao menos 12 caracteres.' }
if ($plainPassword -cne $plainConfirm) { throw 'As senhas não conferem.' }

# 20 bytes aleatórios em Base32, compatível com Google/Microsoft Authenticator.
$alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
$bytes = [byte[]]::new(20)
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$bits = 0; $buffer = 0; $totpSecret = ''
foreach ($byte in $bytes) {
    $buffer = ($buffer -shl 8) -bor $byte; $bits += 8
    while ($bits -ge 5) { $bits -= 5; $totpSecret += $alphabet[($buffer -shr $bits) -band 31] }
}
if ($bits -gt 0) { $totpSecret += $alphabet[($buffer -shl (5 - $bits)) -band 31] }

$dbPasswordSecure = Read-Host "Senha do banco para $DatabaseUser" -AsSecureString
$dbPasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPasswordSecure)
try { $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($dbPasswordPointer) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($dbPasswordPointer) }

try {
    # `-v` trata os valores como variáveis SQL literais; não concatena a senha na consulta.
    $sql = @'
CREATE EXTENSION IF NOT EXISTS pgcrypto;
INSERT INTO admin_accounts (email, password_hash, role, totp_secret)
VALUES (:'email', crypt(:'password', gen_salt('bf', 12)), 'SUPER_ADMIN', :'totp')
;
'@
    $sql | & $Psql -X -v ON_ERROR_STOP=1 -h $DatabaseHost -p $DatabasePort -U $DatabaseUser -d $Database `
        -v "email=$Email" -v "password=$plainPassword" -v "totp=$totpSecret"
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível criar a conta administrativa.' }
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    $plainPassword = $null
    $plainConfirm = $null
}

Write-Host "`nConta SUPER_ADMIN pronta: $Email" -ForegroundColor Green
Write-Host "Cadastre este segredo no seu autenticador agora (ele não será mostrado outra vez):" -ForegroundColor Yellow
Write-Host $totpSecret -ForegroundColor Yellow
Write-Host "Depois, use e-mail, senha e o código de 6 dígitos no painel." -ForegroundColor Cyan
