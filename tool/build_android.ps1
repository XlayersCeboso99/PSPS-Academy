$ErrorActionPreference = 'Stop'
$previousGradleOptions = $env:GRADLE_OPTS
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
  # Java uses the trusted Windows certificate store for this command only.
  $env:GRADLE_OPTS = "$previousGradleOptions -Djavax.net.ssl.trustStoreType=Windows-ROOT -Djavax.net.ssl.trustStore=NONE"
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'No se pudieron resolver las dependencias.' }
  flutter build apk --debug
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar el APK.' }
} finally {
  $env:GRADLE_OPTS = $previousGradleOptions
  Pop-Location
}
