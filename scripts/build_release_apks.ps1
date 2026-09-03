param (
    [Parameter(Mandatory=$false)]
    [string]$RenderApiUrl = "https://turf-booking-app-op86.onrender.com/api"
)

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "📱 TURF ECOSYSTEM: MULTI-APP RELEASE BUILD GENERATOR" -ForegroundColor Cyan
Write-Host "Target Cloud API: $RenderApiUrl" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan

$rootDir = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $rootDir "release_apks"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$apps = @(
    @{ Name = "turf_customer"; Title = "Turf Customer (Players)"; ServerArg = "API_BASE_URL=$RenderApiUrl" },
    @{ Name = "turf_owner"; Title = "Turf Owner (Venue Management)"; ServerArg = "API_SERVER_URL=$($RenderApiUrl.Replace('/api',''))" },
    @{ Name = "turf_staff"; Title = "Turf Staff (Ground Management)"; ServerArg = "API_BASE_URL=$RenderApiUrl" },
    @{ Name = "turf_admin"; Title = "Turf Admin (Governance)"; ServerArg = "API_BASE_URL=$RenderApiUrl" }
)

foreach ($app in $apps) {
    Write-Host "`n🔨 Building release APK for: $($app.Title)..." -ForegroundColor Green
    $appPath = Join-Path $rootDir $app.Name
    
    Push-Location $appPath
    try {
        flutter pub get
        flutter build apk --release "--dart-define=$($app.ServerArg)"
        
        $builtApk = Join-Path $appPath "build\app\outputs\flutter-apk\app-release.apk"
        if (Test-Path $builtApk) {
            $destApk = Join-Path $outputDir "$($app.Name)-release.apk"
            Copy-Item -Path $builtApk -Destination $destApk -Force
            Write-Host "✅ Built successfully: $destApk" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Warning: APK output not found at $builtApk" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Error building $($app.Name): $_" -ForegroundColor Red
    } finally {
        Pop-Location
    }
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "🎉 ALL RELEASE BUILDS PROCESSED!" -ForegroundColor Cyan
Write-Host "Output Directory: $outputDir" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
