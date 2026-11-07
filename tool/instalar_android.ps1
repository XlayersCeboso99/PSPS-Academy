$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
Write-Host "1/4 Analizando el codigo..." -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze reporto problemas." }
Write-Host "2/4 Corriendo las pruebas..." -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { throw "Fallaron las pruebas." }
Write-Host "3/4 Compilando el APK..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "build_android.ps1")
Write-Host "4/4 Instalando en el celular..." -ForegroundColor Cyan
$devices = flutter devices --machine | ConvertFrom-Json
$phone = $devices | Where-Object { $_.targetPlatform -like "android*" -and -not $_.emulator } | Select-Object -First 1
if (-not $phone) { throw "No encontre el celular. Conectalo por USB, desbloquealo y activa la depuracion USB." }
Write-Host ("Celular: " + $phone.name)
flutter install --debug -d $phone.id
if ($LASTEXITCODE -ne 0) { throw "No se pudo instalar en el celular." }
Write-Host "Listo: PSPS Academy instalada en el celular." -ForegroundColor Green
