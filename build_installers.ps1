# Script para compilar ChronoMed en APK o PWA Web
Write-Host "=== COMPILADOR DE INSTALADORES CHRONOMED ===" -ForegroundColor Cyan

$flutterInstalled = Get-Command flutter -ErrorAction SilentlyContinue

if (-not $flutterInstalled) {
    Write-Host "`n⚠️ Flutter SDK no se encuentra en el PATH de este equipo." -ForegroundColor Yellow
    Write-Host "Para compilar el APK nativo tienes 2 opciones:" -ForegroundColor Cyan
    Write-Host "  1. COMPILACIÓN AUTOMÁTICA EN LA NUBE (Recomendada):" -ForegroundColor Green
    Write-Host "     El repositorio cuenta con GitHub Actions (.github/workflows/build_apk.yml)."
    Write-Host "     Cada push o ejecución manual compila automáticamente el archivo 'app-release.apk'"
    Write-Host "     y lo deja disponible para descarga directa en GitHub Releases o Artifacts."
    Write-Host ""
    Write-Host "  2. COMPILACIÓN LOCAL:" -ForegroundColor Green
    Write-Host "     Instala Flutter en Windows ejecutando en PowerShell:"
    Write-Host "       winget install Flutter.Flutter"
    Write-Host "     Luego reinicia PowerShell y vuelve a ejecutar este script."
    Write-Host ""
    exit 0
}

Set-Location "mobile"

Write-Host "1. Obteniendo paquetes de Flutter..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n2. ¿Qué instalador deseas compilar?" -ForegroundColor Cyan
Write-Host "  [1] APK para instalar directo en teléfonos Android (app-release.apk)"
Write-Host "  [2] PWA Web (desplegable en Vercel/Netlify/Firebase/Supabase)"
Write-Host "  [3] Ambos"

$choice = Read-Host "Ingresa 1, 2 o 3"

if ($choice -eq "1" -or $choice -eq "3") {
    Write-Host "`nCompilando APK de Android (Release)..." -ForegroundColor Yellow
    flutter build apk --release
    Write-Host "✅ APK generado en: mobile\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
}

if ($choice -eq "2" -or $choice -eq "3") {
    Write-Host "`nCompilando PWA Web..." -ForegroundColor Yellow
    flutter build web --pwa-strategy=offline-first
    Write-Host "✅ PWA Web generada en: mobile\build\web\" -ForegroundColor Green
}

Write-Host "`n🎉 Compilación finalizada." -ForegroundColor Green
