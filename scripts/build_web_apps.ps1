param (
    [Parameter(Mandatory=$false)]
    [string]$RenderApiUrl = "https://your-turf-api.onrender.com/api"
)

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "🌐 TURF ECOSYSTEM: FLUTTER WEB BUILD GENERATOR" -ForegroundColor Cyan
Write-Host "Target Cloud API: $RenderApiUrl" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan

$rootDir = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $rootDir "release_web"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$apps = @(
    @{ Name = "turf_customer"; Title = "Turf Customer Web Portal"; ServerArg = "API_BASE_URL=$RenderApiUrl" },
    @{ Name = "turf_owner"; Title = "Turf Owner Web Dashboard"; ServerArg = "API_SERVER_URL=$($RenderApiUrl.Replace('/api',''))" }
)

foreach ($app in $apps) {
    Write-Host "`n🔨 Building Web version for: $($app.Title)..." -ForegroundColor Green
    $appPath = Join-Path $rootDir $app.Name
    
    Push-Location $appPath
    try {
        flutter pub get
        flutter build web --release "--dart-define=$($app.ServerArg)"
        
        $builtWeb = Join-Path $appPath "build\web"
        if (Test-Path $builtWeb) {
            $destWeb = Join-Path $outputDir $app.Name
            Copy-Item -Path $builtWeb -Destination $destWeb -Recurse -Force
            Write-Host "✅ Web build completed: $destWeb" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Warning: Web output not found at $builtWeb" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Error building web for $($app.Name): $_" -ForegroundColor Red
    } finally {
        Pop-Location
    }
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "🎉 ALL WEB BUILDS PROCESSED!" -ForegroundColor Cyan
Write-Host "Output Directory: $outputDir" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
