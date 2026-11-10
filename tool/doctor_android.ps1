<#
.SYNOPSIS
  Diagnostico del entorno Android de PSPS Academy (Windows).

.DESCRIPTION
  Verifica Flutter, Java, Android SDK, Platform-Tools, el servidor ADB y los
  dispositivos conectados. No necesita ADB en el PATH: usa el adb.exe del
  Android SDK que Flutter tiene configurado (flutter config --machine).

  Por defecto NO modifica nada: consulta el servidor ADB con el protocolo
  nativo (host:version / host:devices-l), sin reiniciarlo ni matarlo.

  Con -Repair intenta corregir problemas conocidos de ADB. Cada accion que
  afecta procesos o servicios pide confirmacion (usa -Confirm:$false para
  aceptar todo). Nunca borra archivos del SDK, desinstala aplicaciones,
  cambia variables de entorno globales ni el tipo de inicio de servicios.

.PARAMETER Repair
  Intenta reparar los problemas de ADB detectados (previa confirmacion).

.PARAMETER PassThru
  Devuelve un objeto con el resultado (lo usa tool/run_android.ps1).

.EXAMPLE
  .\tool\doctor_android.ps1
.EXAMPLE
  .\tool\doctor_android.ps1 -Repair
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [switch]$Repair,
  [switch]$PassThru
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

# Servicios conocidos que incluyen su propio adb.exe y lo relanzan en el
# puerto 5037. Se detectan ademas de forma generica (adb.exe junto al .exe
# del servicio), esta lista solo aporta un mensaje mas claro.
$knownAdbServices = @{
  'SuperDisplay' = 'SuperDisplay (pantalla secundaria en tablet Android)'
}

$script:problems = New-Object System.Collections.Generic.List[string]
$script:warnings = New-Object System.Collections.Generic.List[string]

function Write-Check([string]$Status, [string]$Title, [string]$Detail) {
  $color = @{ OK = 'Green'; WARN = 'Yellow'; FAIL = 'Red'; INFO = 'Gray' }[$Status]
  Write-Host ('[{0,-4}] {1}' -f $Status, $Title) -ForegroundColor $color
  if ($Detail) { $Detail -split "`n" | ForEach-Object { Write-Host ('       ' + $_) } }
  if ($Status -eq 'FAIL') { $script:problems.Add($Title) }
  if ($Status -eq 'WARN') { $script:warnings.Add($Title) }
}

function Write-Section([string]$Name) { Write-Host ''; Write-Host "== $Name" -ForegroundColor Cyan }

function Invoke-Native([string]$Exe, [string[]]$Arguments) {
  # Ejecuta un programa y devuelve salida+errores como texto, sin que
  # PowerShell 5.1 convierta stderr en excepciones.
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $out = & $Exe @Arguments 2>&1 | ForEach-Object { "$_" }
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($out -join "`n") }
  } finally { $ErrorActionPreference = $old }
}

function Get-AdbPort {
  $p = 0
  if ($env:ANDROID_ADB_SERVER_PORT -and [int]::TryParse($env:ANDROID_ADB_SERVER_PORT, [ref]$p)) { return $p }
  return 5037
}

function Invoke-AdbHostQuery([int]$Port, [string]$Command, [int]$TimeoutMs = 2000) {
  # Habla con el servidor ADB sin usar adb.exe, para no disparar el
  # "server version doesn't match; killing..." del cliente.
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
    if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs)) { return $null }
    $client.EndConnect($async)
    $stream = $client.GetStream()
    $stream.ReadTimeout = $TimeoutMs
    $request = [Text.Encoding]::ASCII.GetBytes(('{0:x4}{1}' -f $Command.Length, $Command))
    $stream.Write($request, 0, $request.Length)
    $read = {
      param([int]$Count)
      $buffer = New-Object byte[] $Count
      $offset = 0
      while ($offset -lt $Count) {
        $n = $stream.Read($buffer, $offset, $Count - $offset)
        if ($n -le 0) { throw 'conexion cerrada' }
        $offset += $n
      }
      [Text.Encoding]::ASCII.GetString($buffer)
    }
    $status = & $read 4
    if ($status -ne 'OKAY') { return $null }
    $length = [Convert]::ToInt32((& $read 4), 16)
    if ($length -eq 0) { return '' }
    return (& $read $length)
  } catch {
    return $null
  } finally {
    $client.Close()
  }
}

function Get-AdbClientVersion([string]$AdbPath) {
  $r = Invoke-Native $AdbPath @('version')
  $proto = if ($r.Text -match 'Android Debug Bridge version 1\.0\.(\d+)') { [int]$Matches[1] } else { $null }
  $release = if ($r.Text -match '(?m)^Version (\S+)') { $Matches[1] } else { '?' }
  [pscustomobject]@{ Path = $AdbPath; Protocol = $proto; Release = $release }
}

function Get-ListenerPid([int]$Port) {
  try {
    $c = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1
    return [int]$c.OwningProcess
  } catch { return $null }
}

function Get-ExePathFromCommandLine([string]$CommandLine) {
  if (-not $CommandLine) { return $null }
  if ($CommandLine -match '^\s*"([^"]+)"') { return $Matches[1] }
  if ($CommandLine -match '^\s*(.+?\.exe)\b') { return $Matches[1] }
  return $null
}

function Resolve-FlutterConfig {
  $cfg = @{}
  $r = Invoke-Native 'flutter' @('config', '--machine')
  $start = $r.Text.IndexOf('{')
  if ($start -ge 0) {
    try {
      $json = $r.Text.Substring($start) | ConvertFrom-Json
      foreach ($p in $json.PSObject.Properties) { $cfg[$p.Name] = $p.Value }
    } catch { }
  }
  return $cfg
}

# ---------------------------------------------------------------- Flutter
Write-Section 'Flutter'
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
$flutterConfig = @{}
if (-not $flutterCmd) {
  Write-Check FAIL 'Flutter no esta en el PATH' "Instala Flutter estable (https://docs.flutter.dev/get-started/install)`ny agrega flutter\bin al PATH. Ver docs/SETUP.md."
} else {
  $v = Invoke-Native 'flutter' @('--version', '--machine')
  $vjson = $null
  try { $vjson = $v.Text.Substring($v.Text.IndexOf('{')) | ConvertFrom-Json } catch { }
  if ($vjson) {
    $dart = [version]($vjson.dartSdkVersion -replace '[^0-9.].*$', '')
    $required = [version]'3.13.2'
    $pubspec = Join-Path $projectRoot 'pubspec.yaml'
    if ((Test-Path $pubspec) -and ((Get-Content $pubspec -Raw) -match 'sdk:\s*\^?(\d+\.\d+\.\d+)')) { $required = [version]$Matches[1] }
    $detail = "Flutter $($vjson.frameworkVersion) ($($vjson.channel)), Dart $($vjson.dartSdkVersion)`nRuta: $($vjson.flutterRoot)"
    if ($dart -ge $required) { Write-Check OK 'Flutter' $detail }
    else { Write-Check FAIL "Dart $dart es menor que el requerido ($required)" "$detail`nActualiza Flutter al canal estable (flutter upgrade) cuando lo autorices." }
  } else {
    Write-Check WARN 'No se pudo leer la version de Flutter' $v.Text
  }
  $flutterConfig = Resolve-FlutterConfig
}

# ------------------------------------------------------------ Android SDK
Write-Section 'Android SDK'
$sdkCandidates = @(
  @{ Source = 'flutter config (android-sdk)'; Path = $flutterConfig['android-sdk'] },
  @{ Source = 'ANDROID_HOME'; Path = $env:ANDROID_HOME },
  @{ Source = 'ANDROID_SDK_ROOT'; Path = $env:ANDROID_SDK_ROOT },
  @{ Source = 'ubicacion por defecto'; Path = (Join-Path $env:LOCALAPPDATA 'Android\Sdk') }
)
$sdk = $null
foreach ($c in $sdkCandidates) {
  if ($c.Path -and (Test-Path -LiteralPath $c.Path)) { $sdk = [pscustomobject]@{ Path = (Resolve-Path -LiteralPath $c.Path).Path; Source = $c.Source }; break }
}
foreach ($envName in 'ANDROID_HOME', 'ANDROID_SDK_ROOT') {
  $val = [Environment]::GetEnvironmentVariable($envName)
  if ($val -and $sdk -and ((Resolve-Path -LiteralPath $val -ErrorAction SilentlyContinue).Path -ne $sdk.Path)) {
    Write-Check WARN "$envName apunta a otro SDK" "$envName = $val`nFlutter usa: $($sdk.Path)`nDos SDK distintos suelen implicar dos versiones de ADB."
  }
}
$sdkAdb = $null
if (-not $sdk) {
  Write-Check FAIL 'No se encontro el Android SDK' "Instala Android Studio (o las command-line tools) y ejecuta`n  flutter config --android-sdk <ruta-del-sdk>"
} else {
  Write-Check OK 'Android SDK' "$($sdk.Path)`n(detectado via $($sdk.Source))"
  $platforms = @(Get-ChildItem (Join-Path $sdk.Path 'platforms') -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
  $buildTools = @(Get-ChildItem (Join-Path $sdk.Path 'build-tools') -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
  if ($platforms.Count -and $buildTools.Count) { Write-Check OK 'Plataformas y Build-Tools' ("platforms: " + ($platforms -join ', ') + "`nbuild-tools: " + ($buildTools -join ', ')) }
  else { Write-Check FAIL 'Faltan plataformas o Build-Tools' 'Instalalos desde Android Studio > SDK Manager.' }
  if (Test-Path (Join-Path $sdk.Path 'licenses\android-sdk-license')) { Write-Check OK 'Licencias del SDK aceptadas' '' }
  else { Write-Check FAIL 'Licencias del SDK sin aceptar' 'Ejecuta: flutter doctor --android-licenses' }

  $candidate = Join-Path $sdk.Path 'platform-tools\adb.exe'
  if (Test-Path -LiteralPath $candidate) {
    $sdkAdb = Get-AdbClientVersion $candidate
    $ptRev = (Select-String -Path (Join-Path $sdk.Path 'platform-tools\source.properties') -Pattern 'Pkg.Revision=(.+)' -ErrorAction SilentlyContinue | ForEach-Object { $_.Matches[0].Groups[1].Value })
    Write-Check OK 'Platform-Tools' "adb $($sdkAdb.Release) (protocolo 1.0.$($sdkAdb.Protocol)), paquete $ptRev`n$candidate"
  } else {
    Write-Check FAIL 'Falta Platform-Tools (adb.exe)' 'Instala "Android SDK Platform-Tools" desde el SDK Manager.'
  }
}

# ------------------------------------------------------------------- Java
Write-Section 'Java (JDK que usa Gradle)'
$javaCandidates = @(
  @{ Source = 'flutter config (jdk-dir)'; Home = $flutterConfig['jdk-dir'] },
  @{ Source = 'Android Studio (jbr)'; Home = $(if ($flutterConfig['android-studio-dir']) { Join-Path $flutterConfig['android-studio-dir'] 'jbr' }) },
  @{ Source = 'JAVA_HOME'; Home = $env:JAVA_HOME }
)
$java = $null
foreach ($c in $javaCandidates) {
  if ($c.Home -and (Test-Path -LiteralPath (Join-Path $c.Home 'bin\java.exe'))) { $java = [pscustomobject]@{ Exe = (Join-Path $c.Home 'bin\java.exe'); Source = $c.Source }; break }
}
if (-not $java) {
  $onPath = Get-Command java -ErrorAction SilentlyContinue
  if ($onPath) { $java = [pscustomobject]@{ Exe = $onPath.Source; Source = 'PATH' } }
}
if (-not $java) {
  Write-Check FAIL 'No se encontro un JDK' 'Instala Android Studio (incluye JDK) o un JDK 17+ y ejecuta flutter config --jdk-dir <ruta>.'
} else {
  $jv = Invoke-Native $java.Exe @('-version')
  $major = if ($jv.Text -match 'version "(\d+)') { [int]$Matches[1] } else { 0 }
  if ($major -eq 1 -and $jv.Text -match 'version "1\.(\d+)') { $major = [int]$Matches[1] }
  $first = ($jv.Text -split "`n")[0]
  if ($major -ge 17) { Write-Check OK "Java $major" "$first`n$($java.Exe) (via $($java.Source))" }
  else { Write-Check FAIL "Java $major es menor que 17" "$($java.Exe)`nEl proyecto compila con Java 17+ (AGP 9 / Gradle 9)." }
}

# -------------------------------------------------------------------- ADB
Write-Section 'ADB'
$port = Get-AdbPort
if ($port -ne 5037) { Write-Check INFO "ANDROID_ADB_SERVER_PORT=$port" 'Se usa ese puerto en lugar de 5037.' }

$pathAdb = @(Get-Command adb -All -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
if (-not $pathAdb.Count) {
  Write-Check INFO 'adb no esta en el PATH' 'No es necesario: los scripts usan el adb del SDK (ruta en Platform-Tools, arriba).'
} else {
  foreach ($p in $pathAdb) {
    if ($sdkAdb -and $p -ne $sdkAdb.Path) {
      $v = Get-AdbClientVersion $p
      Write-Check WARN 'Hay otro adb.exe antes en el PATH' "$p (adb $($v.Release), protocolo 1.0.$($v.Protocol))`nUsar adb a mano desde aqui puede reiniciar el servidor con otra version."
    }
  }
}

# Servicios de Windows que traen su propio adb.exe.
$conflicts = @()
try {
  $services = Get-CimInstance Win32_Service -ErrorAction Stop
  foreach ($svc in $services) {
    $exe = Get-ExePathFromCommandLine $svc.PathName
    if (-not $exe) { continue }
    $dir = Split-Path -Parent $exe
    foreach ($rel in 'adb.exe', 'adb\adb.exe', 'platform-tools\adb.exe') {
      $adbHere = Join-Path $dir $rel
      if ((Test-Path -LiteralPath $adbHere) -and (-not $sdkAdb -or $adbHere -ne $sdkAdb.Path)) {
        $v = Get-AdbClientVersion $adbHere
        $conflicts += [pscustomobject]@{
          Service = $svc.Name; DisplayName = $svc.DisplayName; State = $svc.State; StartMode = $svc.StartMode
          Adb = $adbHere; Protocol = $v.Protocol; Release = $v.Release
          Label = $(if ($knownAdbServices.ContainsKey($svc.Name)) { $knownAdbServices[$svc.Name] } else { $svc.DisplayName })
        }
      }
    }
  }
} catch { Write-Check WARN 'No se pudieron listar los servicios de Windows' $_.Exception.Message }

# Procesos adb.exe activos.
$adbProcs = @(Get-Process adb -ErrorAction SilentlyContinue)
$mySession = [Diagnostics.Process]::GetCurrentProcess().SessionId
if ($adbProcs.Count) {
  $lines = foreach ($p in $adbProcs) {
    $path = $null; try { $path = $p.Path } catch { }
    if (-not $path) { $path = '(ruta no accesible: lo inicio un servicio u otro usuario)' }
    $origin = if ($p.SessionId -eq 0) { 'sesion 0 = servicio de Windows' } elseif ($p.SessionId -eq $mySession) { 'tu sesion' } else { "sesion $($p.SessionId)" }
    "PID $($p.Id) [$origin] $path"
  }
  $st = if ($adbProcs.Count -gt 1) { 'WARN' } else { 'INFO' }
  Write-Check $st ("Procesos adb.exe activos: {0}" -f $adbProcs.Count) ($lines -join "`n")
} else {
  Write-Check INFO 'No hay procesos adb.exe activos' 'El servidor se iniciara al ejecutar Flutter o run_android.ps1.'
}

# Servidor en el puerto: version y estabilidad (sin reiniciarlo).
$serverVersion = $null
$stable = $true
$samples = @()
foreach ($i in 1..3) {
  $raw = Invoke-AdbHostQuery $port 'host:version'
  $ver = if ($raw) { [Convert]::ToInt32($raw, 16) } else { $null }
  $samples += [pscustomobject]@{ Version = $ver; Listener = (Get-ListenerPid $port) }
  if ($i -lt 3) { Start-Sleep -Milliseconds 1500 }
}
$versions = @($samples | ForEach-Object { $_.Version } | Select-Object -Unique)
$listeners = @($samples | Where-Object { $_.Listener } | ForEach-Object { $_.Listener } | Select-Object -Unique)
$serverVersion = $samples[-1].Version
if ($versions.Count -gt 1 -or $listeners.Count -gt 1) { $stable = $false }

if ($null -eq $serverVersion -and -not ($samples | Where-Object { $_.Version }) -and $adbProcs.Count) {
  $stable = $false
  Write-Check FAIL "El servidor ADB del puerto $port no responde" 'Hay procesos adb.exe activos pero no contestan; suele ser un servidor reiniciandose o de otra version.'
} elseif ($null -eq $serverVersion -and -not ($samples | Where-Object { $_.Version })) {
  Write-Check INFO "Ningun servidor ADB escucha en el puerto $port" 'Es normal si nadie lo ha iniciado.'
} elseif (-not $stable) {
  Write-Check FAIL "Servidor ADB inestable en el puerto $port" ("Muestras (version/PID): " + (($samples | ForEach-Object { "1.0.$($_.Version)/$($_.Listener)" }) -join ', ') +
    "`nDos programas reinician el servidor una y otra vez (sintomas: 'connection reset', 'Android null').")
} elseif ($sdkAdb -and $serverVersion -ne $sdkAdb.Protocol) {
  Write-Check FAIL "Servidor ADB 1.0.$serverVersion distinto al cliente del SDK 1.0.$($sdkAdb.Protocol)" "Flutter matara ese servidor ('adb server version ($serverVersion) doesn't match this client ($($sdkAdb.Protocol))')`ny el programa que lo inicio puede volver a lanzarlo."
} else {
  Write-Check OK "Servidor ADB 1.0.$serverVersion estable en el puerto $port" ''
}
$adbHealthy = $sdkAdb -and $stable -and ($serverVersion -eq $sdkAdb.Protocol)

# Un servicio con otro adb es la causa del problema si el servidor no esta
# sano; si ahora esta sano, sigue siendo un riesgo (lo reemplazara al volver
# a conectarse), por eso se informa como aviso.
foreach ($c in $conflicts) {
  $mismatch = $sdkAdb -and $c.Protocol -and $c.Protocol -ne $sdkAdb.Protocol
  $status = if ($c.State -ne 'Running') { 'INFO' } elseif ($mismatch -and -not $adbHealthy) { 'FAIL' } else { 'WARN' }
  Write-Check $status "Servicio con ADB propio: $($c.Label)" ("Servicio '$($c.Service)' ($($c.State), inicio $($c.StartMode))`nadb $($c.Release) (protocolo 1.0.$($c.Protocol)): $($c.Adb)" +
    $(if ($mismatch) { "`nDistinto al del SDK (1.0.$($sdkAdb.Protocol)): ambos se disputan el puerto $port y se reinician entre si." } else { '' }))
}

# ------------------------------------------------------------ Dispositivos
Write-Section 'Dispositivos Android'
$devices = @()
$rawDevices = Invoke-AdbHostQuery $port 'host:devices-l'
if ($null -ne $rawDevices) {
  foreach ($line in ($rawDevices -split "`n")) {
    $t = $line.Trim() -split '\s+'
    if ($t.Count -lt 2 -or -not $t[0]) { continue }
    $model = ($t | Where-Object { $_ -like 'model:*' } | Select-Object -First 1)
    $devices += [pscustomobject]@{ Id = $t[0]; State = $t[1]; Model = $(if ($model) { $model.Substring(6) } else { '' }); Android = ''; Api = '' }
  }
}
if ($adbHealthy) {
  foreach ($d in $devices | Where-Object { $_.State -eq 'device' }) {
    $d.Android = (Invoke-Native $sdkAdb.Path @('-s', $d.Id, 'shell', 'getprop', 'ro.build.version.release')).Text.Trim()
    $d.Api = (Invoke-Native $sdkAdb.Path @('-s', $d.Id, 'shell', 'getprop', 'ro.build.version.sdk')).Text.Trim()
  }
}
if (-not $devices.Count) {
  Write-Check WARN 'No hay dispositivos conectados' ("Conecta el telefono por USB con un cable de datos, desbloquealo y activa`nOpciones de desarrollador > Depuracion USB. O inicia un emulador desde Android Studio > Device Manager." +
    $(if ($null -eq $rawDevices) { "`n(No se pudo consultar el servidor ADB.)" } else { '' }))
}
foreach ($d in $devices) {
  $name = "$($d.Id) $($d.Model)".Trim()
  switch ($d.State) {
    'device' {
      if ($adbHealthy -and $d.Api) { Write-Check OK "$name listo" "Android $($d.Android) (API $($d.Api))" }
      else { Write-Check WARN "$name conectado, pero ADB no es estable" 'Flutter lo mostrara como "Android null (unsupported)" hasta reparar ADB.' }
    }
    'unauthorized' { Write-Check FAIL "$name sin autorizar" "Desbloquea el telefono y acepta 'Permitir depuracion USB' (marca 'Permitir siempre').`nSi no aparece: Opciones de desarrollador > Revocar autorizaciones, desconecta y vuelve a conectar." }
    'offline' { Write-Check FAIL "$name offline" "Desconecta y reconecta el cable, desbloquea el telefono y, si sigue igual,`nejecuta tool\doctor_android.ps1 -Repair para reiniciar el servidor ADB." }
    'no' { Write-Check FAIL "$name sin permisos" 'Revisa el controlador USB (Samsung: instala Samsung Android USB Driver).' }
    default { Write-Check WARN "$name en estado '$($d.State)'" 'Espera unos segundos y vuelve a ejecutar el diagnostico.' }
  }
}

# --------------------------------------------------------------- Reparar
if ($Repair) {
  Write-Section 'Reparacion'
  $repaired = $false
  $running = @($conflicts | Where-Object { $_.State -eq 'Running' -and $sdkAdb -and $_.Protocol -ne $sdkAdb.Protocol })
  foreach ($c in $running) {
    Write-Host "El servicio '$($c.Service)' relanza su adb 1.0.$($c.Protocol) y desplaza al del SDK."
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
      Write-Check WARN "Detener '$($c.Service)' requiere administrador" ("Abre PowerShell como administrador y ejecuta:`n  Stop-Service -Name '$($c.Service)'`n" +
        "Al terminar de desarrollar, vuelve a iniciarlo con:`n  Start-Service -Name '$($c.Service)'`nDespues ejecuta de nuevo: .\tool\doctor_android.ps1 -Repair")
      continue
    }
    if ($PSCmdlet.ShouldProcess("servicio $($c.Service) ($($c.Label))", 'Detener temporalmente (no cambia su tipo de inicio)')) {
      Stop-Service -Name $c.Service -ErrorAction Stop
      Write-Check OK "Servicio '$($c.Service)' detenido" "Vuelve a iniciarlo cuando lo necesites: Start-Service -Name '$($c.Service)'"
      $repaired = $true
    }
  }
  $stillConflict = @($running | Where-Object { (Get-Service -Name $_.Service -ErrorAction SilentlyContinue).Status -eq 'Running' })
  if ($adbHealthy) {
    Write-Check OK 'El servidor ADB actual es el del SDK; no se reinicia' ''
  } elseif ($stillConflict.Count) {
    Write-Check WARN 'No se reinicio ADB' 'Mientras el servicio siga activo volvera a reemplazar el servidor; detenlo primero.'
  } elseif ($sdkAdb) {
    if ($PSCmdlet.ShouldProcess("servidor ADB en el puerto $port", "Reiniciar con el adb del SDK ($($sdkAdb.Path))")) {
      Invoke-Native $sdkAdb.Path @('kill-server') | Out-Null
      Start-Sleep -Seconds 1
      $r = Invoke-Native $sdkAdb.Path @('start-server')
      Start-Sleep -Seconds 2
      $raw = Invoke-AdbHostQuery $port 'host:version'
      if ($raw -and [Convert]::ToInt32($raw, 16) -eq $sdkAdb.Protocol) { Write-Check OK 'Servidor ADB reiniciado con el del SDK' $r.Text; $repaired = $true }
      else { Write-Check FAIL 'El servidor ADB no quedo con la version del SDK' 'Otro programa lo esta relanzando. Revisa los servicios listados arriba.' }
    }
  }
  if ($repaired) {
    Write-Host ''
    Write-Host 'Volviendo a diagnosticar...' -ForegroundColor Cyan
    if ($PassThru) { return (& $PSCommandPath -PassThru) }
    & $PSCommandPath
    exit $LASTEXITCODE
  }
}

# --------------------------------------------------------------- Resumen
Write-Section 'Resumen'
if ($script:problems.Count) {
  Write-Host ("{0} problema(s): {1}" -f $script:problems.Count, ($script:problems -join '; ')) -ForegroundColor Red
  if (-not $Repair -and -not $adbHealthy -and $sdkAdb) {
    Write-Host 'Prueba: .\tool\doctor_android.ps1 -Repair' -ForegroundColor Yellow
  }
} elseif ($script:warnings.Count) {
  Write-Host ("Sin errores; {0} aviso(s)." -f $script:warnings.Count) -ForegroundColor Yellow
} else {
  Write-Host 'Entorno Android listo.' -ForegroundColor Green
}

if ($PassThru) {
  [pscustomobject]@{
    Ok = ($script:problems.Count -eq 0)
    AdbHealthy = [bool]$adbHealthy
    SdkPath = $(if ($sdk) { $sdk.Path })
    AdbPath = $(if ($sdkAdb) { $sdkAdb.Path })
    Devices = $devices
    Conflicts = $conflicts
    Problems = $script:problems.ToArray()
  }
} elseif ($script:problems.Count) {
  exit 1
}
