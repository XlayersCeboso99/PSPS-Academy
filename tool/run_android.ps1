<#
.SYNOPSIS
  Ejecuta PSPS Academy en un dispositivo Android con una sola instruccion.

.DESCRIPTION
  1. Ejecuta tool/doctor_android.ps1 (con -Repair si se indica).
  2. Elige el dispositivo: el indicado con -DeviceId o, si solo hay uno
     listo, ese. Si esta sin autorizar, offline o no aparece, explica que hacer.
  3. flutter pub get --enforce-lockfile y flutter run -d <id>.

  Flutter usa el adb del SDK que detecta el diagnostico; para este proceso
  se fija ANDROID_HOME a ese SDK (no se modifican variables globales).

.EXAMPLE
  .\tool\run_android.ps1
.EXAMPLE
  .\tool\run_android.ps1 -DeviceId R5GYC1M5TNN
.EXAMPLE
  .\tool\run_android.ps1 -Repair -Mode profile
#>
[CmdletBinding()]
param(
  [string]$DeviceId,
  [ValidateSet('debug', 'profile', 'release')][string]$Mode = 'debug',
  [switch]$Repair,
  [switch]$SkipPubGet,
  # Argumentos extra para flutter run, por ejemplo: -FlutterArgs '--verbose'
  [string[]]$FlutterArgs = @()
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Stop-WithHelp([string]$Message, [string]$Help) {
  Write-Host ''
  Write-Host $Message -ForegroundColor Red
  if ($Help) { Write-Host $Help }
  exit 1
}

$doctorArgs = @{ PassThru = $true }
if ($Repair) { $doctorArgs.Repair = $true }
$report = & (Join-Path $PSScriptRoot 'doctor_android.ps1') @doctorArgs
if ($report -is [array]) { $report = $report[-1] }

if (-not $report -or -not $report.SdkPath -or -not $report.AdbPath) {
  Stop-WithHelp 'Falta Flutter o el Android SDK.' 'Corrige los puntos [FAIL] de arriba (ver docs/SETUP.md) y vuelve a intentarlo.'
}
if (-not $report.AdbHealthy) {
  Stop-WithHelp 'ADB no esta estable; Flutter no podra instalar la app.' "Ejecuta: .\tool\run_android.ps1 -Repair`n(o .\tool\doctor_android.ps1 -Repair y sigue sus instrucciones)."
}

$devices = @($report.Devices)
$ready = @($devices | Where-Object { $_.State -eq 'device' })
$connectHelp = "1. Conecta el telefono por USB con un cable de datos y desbloquealo.`n" +
  "2. Ajustes > Acerca del telefono > Informacion de software: toca 7 veces 'Numero de compilacion'.`n" +
  "3. Opciones de desarrollador > activa 'Depuracion USB'.`n" +
  "4. Acepta 'Permitir depuracion USB' en el telefono.`n" +
  "O inicia un emulador: Android Studio > Device Manager. Luego: .\tool\run_android.ps1"

$target = $null
if ($DeviceId) {
  $target = $devices | Where-Object { $_.Id -eq $DeviceId } | Select-Object -First 1
  if (-not $target) {
    $list = if ($devices.Count) { "Dispositivos vistos: " + (($devices | ForEach-Object { "$($_.Id) ($($_.State))" }) -join ', ') } else { 'No se ve ningun dispositivo.' }
    Stop-WithHelp "El dispositivo '$DeviceId' no esta conectado." "$list`n$connectHelp"
  }
} elseif ($ready.Count -eq 1) {
  $target = $ready[0]
} elseif ($ready.Count -gt 1) {
  $list = ($ready | ForEach-Object { "  .\tool\run_android.ps1 -DeviceId $($_.Id)   # $($_.Model) Android $($_.Android)" }) -join "`n"
  Stop-WithHelp 'Hay varios dispositivos listos; elige uno:' $list
} elseif ($devices.Count) {
  $target = $devices[0]
} else {
  Stop-WithHelp 'No hay ningun dispositivo Android conectado.' $connectHelp
}

switch ($target.State) {
  'device' { }
  'unauthorized' {
    Stop-WithHelp "$($target.Id) no ha autorizado esta computadora." ("Desbloquea el telefono y acepta 'Permitir depuracion USB' (marca 'Permitir siempre').`n" +
      "Si el aviso no aparece: Opciones de desarrollador > Revocar autorizaciones de depuracion USB,`ndesconecta y vuelve a conectar el cable. Luego repite el comando.")
  }
  'offline' {
    Stop-WithHelp "$($target.Id) esta offline." "Desconecta y reconecta el cable, desbloquea el telefono y ejecuta:`n  .\tool\run_android.ps1 -Repair"
  }
  default {
    Stop-WithHelp "$($target.Id) esta en estado '$($target.State)'." 'Espera unos segundos, reconecta el cable y repite el comando.'
  }
}

Write-Host ''
Write-Host ("Dispositivo: {0} {1} (Android {2}, API {3})" -f $target.Id, $target.Model, $target.Android, $target.Api) -ForegroundColor Cyan

$previousAndroidHome = $env:ANDROID_HOME
Push-Location $projectRoot
try {
  # Solo para este proceso: Flutter y Gradle usan el mismo SDK (y adb) que el diagnostico.
  $env:ANDROID_HOME = $report.SdkPath
  if (-not $SkipPubGet) {
    flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { Stop-WithHelp 'flutter pub get --enforce-lockfile fallo.' 'pubspec.lock no coincide con pubspec.yaml o no hay red. No ejecutes "flutter pub upgrade" en esta rama.' }
  }
  flutter run -d $target.Id "--$Mode" @FlutterArgs
  if ($LASTEXITCODE -ne 0) { Stop-WithHelp 'flutter run termino con error.' 'Revisa el registro de arriba. Para el diagnostico: .\tool\doctor_android.ps1' }
} finally {
  $env:ANDROID_HOME = $previousAndroidHome
  Pop-Location
}
