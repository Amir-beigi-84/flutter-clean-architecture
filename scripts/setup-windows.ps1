
###############################################################################
# Flutter Clean Architecture Structure Generator (Windows)
# Creates folder structure and empty files based on user-provided features
# Version: 4.6 • Updated: 2025-10-25
###############################################################################

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ---- Colors and Logging ----
function Write-Info {
    Write-Host "[INFO] " -ForegroundColor Cyan -NoNewline
    Write-Host $args
}

function Write-Success {
    Write-Host "[ OK ] " -ForegroundColor Green -NoNewline
    Write-Host $args
}

function Write-Warn {
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $args
}

function Write-Fail {
    Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
    Write-Host $args
    exit 1
}

# ---- Banner ----
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Flutter Clean Architecture Structure Generator          ║" -ForegroundColor Cyan
Write-Host "║   Creates empty files for your features                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ---- Environment Validation ----
Write-Info "Validating environment..."

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Fail "Flutter not found in PATH."
}

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    Write-Fail "Dart not found in PATH."
}

if (-not (Test-Path "pubspec.yaml")) {
    Write-Fail "pubspec.yaml not found. Run from project root."
}

$flutterVersion = (flutter --version 2>$null | Select-Object -First 1).Split()[1]
Write-Success "Flutter detected: $flutterVersion"
Write-Host ""

# ---- Helper Functions ----
function Confirm-Action {
    param([string]$Message)
    $response = Read-Host "? $Message [y/N]"
    return $response -match '^[Yy]$'
}

function Show-Menu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    Write-Info $Title
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host "  $($i + 1)) $($Options[$i])"
    }

    do {
        $selection = Read-Host "→ Choice (1-$($Options.Length))"
        $index = [int]$selection - 1
    } while ($index -lt 0 -or $index -ge $Options.Length)

    return $Options[$index]
}

# ---- Collect Configuration ----
$appNameInput = Read-Host "→ App Display Name (press Enter to keep current)"
if ([string]::IsNullOrWhiteSpace($appNameInput)) {
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    if ($pubspecContent -match 'name:\s*(.+)') {
        $APP_NAME = $matches[1].Trim()
    } else {
        $APP_NAME = "My Flutter App"
    }
} else {
    $APP_NAME = $appNameInput
}

Write-Host ""
$STATE_MGMT = Show-Menu -Title "Select state management solution:" -Options @("bloc", "riverpod", "provider", "getx")

Write-Host ""
$ROUTER = Show-Menu -Title "Select navigation solution:" -Options @("none", "go_router")

Write-Host ""
$PROFILE = Show-Menu -Title "Select dependency profile:" -Options @("minimal", "standard", "full")

# ---- Collect Feature Names ----
Write-Host ""
Write-Info "Enter your feature names (comma-separated)"
Write-Info "Example: auth,profile,settings,dashboard"
Write-Host ""
$featuresInput = Read-Host "→ Features"

# Parse and validate features
$FEATURES = $featuresInput -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }

if ($FEATURES.Count -eq 0) {
    Write-Fail "No features provided. Please enter at least one feature name."
}

Write-Host ""
$SKIP_INSTALL = Confirm-Action "Skip dependency installation (structure only)?"

# ---- Configuration Summary ----
Write-Host ""
Write-Info "Configuration Summary:"
Write-Host "  ✓ App Name:     $APP_NAME"
Write-Host "  ✓ State Mgmt:   $STATE_MGMT"
Write-Host "  ✓ Router:       $ROUTER"
Write-Host "  ✓ Profile:      $PROFILE"
Write-Host "  ✓ Features:     $($FEATURES -join ', ')"
Write-Host "  ✓ Skip Install: $SKIP_INSTALL"
Write-Host ""

if (-not (Confirm-Action "Proceed with structure generation?")) {
    Write-Warn "Cancelled by user."
    exit 0
}

# ---- Dependency Resolution ----
$deps = @("get_it", "dio", "equatable")

switch ($STATE_MGMT) {
    "bloc"     { $deps += "flutter_bloc" }
    "riverpod" { $deps += "flutter_riverpod" }
    "provider" { $deps += "provider" }
    "getx"     { $deps += "get" }
}

switch ($PROFILE) {
    "minimal"  { $deps += "fpdart" }
    "standard" { $deps += @("connectivity_plus", "pretty_dio_logger", "fpdart") }
    "full"     { $deps += @("connectivity_plus", "pretty_dio_logger", "shared_preferences", "flutter_secure_storage", "fpdart", "json_annotation") }
}

if ($ROUTER -eq "go_router") {
    $deps += "go_router"
}

# ---- Installation Phase ----
Write-Host ""
if (-not $SKIP_INSTALL) {
    Write-Info "Installing $($deps.Count) dependencies..."
    $depsString = $deps -join " "
    dart pub add $depsString.Split() 2>&1 | Where-Object { $_ -notmatch "Resolving dependencies" }
    Write-Success "Dependencies installed."

    switch ($PROFILE) {
        "full" {
            Write-Info "Installing dev dependencies..."
            dart pub add -d flutter_lints build_runner json_serializable 2>&1 | Where-Object { $_ -notmatch "Resolving dependencies" }
        }
        "standard" {
            dart pub add -d flutter_lints 2>&1 | Where-Object { $_ -notmatch "Resolving dependencies" }
        }
    }
} else {
    Write-Warn "Skipped dependency installation."
}

# ---- Create Directory Structure ----
Write-Host ""
Write-Info "Creating directory structure..."

# Core directories
$coreDirs = @(
    "lib/src/core/constants",
    "lib/src/core/network",
    "lib/src/core/error",
    "lib/src/core/theme",
    "lib/src/core/di",
    "lib/src/core/usecase",
    "lib/src/core/utils"
)

foreach ($dir in $coreDirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

if ($ROUTER -eq "go_router") {
    New-Item -ItemType Directory -Force -Path "lib/src/core/router" | Out-Null
}

# Feature directories
foreach ($feature in $FEATURES) {
    $featureDirs = @(
        "lib/src/features/$feature/domain/entities",
        "lib/src/features/$feature/domain/repositories",
        "lib/src/features/$feature/domain/usecases",
        "lib/src/features/$feature/data/models",
        "lib/src/features/$feature/data/datasources",
        "lib/src/features/$feature/data/repositories"
    )

    $presentationSubdir = switch ($STATE_MGMT) {
        "bloc"     { "bloc" }
        "riverpod" { "providers" }
        "provider" { "notifiers" }
        "getx"     { "controllers" }
    }

    $featureDirs += @(
        "lib/src/features/$feature/presentation/$presentationSubdir",
        "lib/src/features/$feature/presentation/pages",
        "lib/src/features/$feature/presentation/widgets"
    )

    foreach ($dir in $featureDirs) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

Write-Success "Directory structure created."

# ---- Create Core Files ----
Write-Host ""
Write-Info "Creating core files..."

$coreFiles = @(
    "lib/src/core/constants/app_constants.dart",
    "lib/src/core/error/failures.dart",
    "lib/src/core/error/exceptions.dart",
    "lib/src/core/usecase/usecase.dart",
    "lib/src/core/theme/app_theme.dart",
    "lib/src/core/di/injection.dart"
)

if ($PROFILE -ne "minimal") {
    $coreFiles += @(
        "lib/src/core/network/network_info.dart",
        "lib/src/core/network/dio_client.dart"
    )
}

if ($ROUTER -eq "go_router") {
    $coreFiles += "lib/src/core/router/app_router.dart"
}

foreach ($file in $coreFiles) {
    New-Item -ItemType File -Force -Path $file | Out-Null
}

Write-Success "Core files created."

# ---- Generate Feature Files ----
Write-Host ""
Write-Info "Generating feature files..."

foreach ($feature in $FEATURES) {
    Write-Info "  → Creating files for: $feature"

    # Domain layer
    $domainFiles = @(
        "lib/src/features/$feature/domain/entities/${feature}_entity.dart",
        "lib/src/features/$feature/domain/repositories/${feature}_repository.dart",
        "lib/src/features/$feature/domain/usecases/get_${feature}.dart"
    )

    # Data layer
    $dataFiles = @(
        "lib/src/features/$feature/data/models/${feature}_model.dart",
        "lib/src/features/$feature/data/datasources/${feature}_remote_data_source.dart",
        "lib/src/features/$feature/data/datasources/${feature}_local_data_source.dart",
        "lib/src/features/$feature/data/repositories/${feature}_repository_impl.dart"
    )

    # Presentation layer
    $presentationFiles = @(
        "lib/src/features/$feature/presentation/pages/${feature}_page.dart",
        "lib/src/features/$feature/presentation/widgets/${feature}_widget.dart"
    )

    switch ($STATE_MGMT) {
        "bloc" {
            $presentationFiles += @(
                "lib/src/features/$feature/presentation/bloc/${feature}_bloc.dart",
                "lib/src/features/$feature/presentation/bloc/${feature}_event.dart",
                "lib/src/features/$feature/presentation/bloc/${feature}_state.dart"
            )
        }
        "riverpod" {
            $presentationFiles += "lib/src/features/$feature/presentation/providers/${feature}_provider.dart"
        }
        "provider" {
            $presentationFiles += "lib/src/features/$feature/presentation/notifiers/${feature}_notifier.dart"
        }
        "getx" {
            $presentationFiles += "lib/src/features/$feature/presentation/controllers/${feature}_controller.dart"
        }
    }

    $allFiles = $domainFiles + $dataFiles + $presentationFiles
    foreach ($file in $allFiles) {
        New-Item -ItemType File -Force -Path $file | Out-Null
    }

    Write-Success "  ✓ Feature '$feature' files created"
}

# ---- App Entry Points ----
New-Item -ItemType File -Force -Path "lib/src/app.dart" | Out-Null
New-Item -ItemType File -Force -Path "lib/main.dart" | Out-Null

# ---- Analysis Options ----
$analysisOptions = @'
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
    require_trailing_commas: true
    always_use_package_imports: true
    prefer_const_constructors: true
    avoid_print: true
'@

Set-Content -Path "analysis_options.yaml" -Value $analysisOptions

# ---- Architecture Documentation ----
$featuresList = ($FEATURES | ForEach-Object { "- **$_**" }) -join "`n"
$featureStructure = ($FEATURES | ForEach-Object { "│   ├── $_/" }) -join "`n"

$architectureMd = @"
# $APP_NAME - Architecture

**State Management:** $STATE_MGMT
**Router:** $ROUTER
**Profile:** $PROFILE

## Features

$featuresList

## Clean Architecture Layers

### Domain Layer (Business Logic)
- **Entities**: Core business objects
- **Repositories**: Contracts/interfaces
- **Use Cases**: Application-specific business rules

### Data Layer (Implementation)
- **Models**: Data transfer objects
- **Data Sources**: Remote (API) and Local (DB/Cache)
- **Repository Implementations**: Concrete implementations

### Presentation Layer (UI)
- **Pages**: Screen layouts
- **Widgets**: Reusable UI components
- **State Management** ($STATE_MGMT): State holders

## Project Structure



## Next Steps

1. Implement entities in ``domain/entities/``
2. Define repository contracts in ``domain/repositories/``
3. Create use cases in ``domain/usecases/``
4. Implement models and data sources in ``data/``
5. Build UI in ``presentation/``
6. Configure DI in ``core/di/injection.dart``
7. Run: ``flutter run``
"@

Set-Content -Path "ARCHITECTURE.md" -Value $architectureMd

Write-Success "Architecture documentation created: ARCHITECTURE.md"

# ---- Final Summary ----
Write-Host ""
Write-Success "✓ Project structure generated successfully!"
Write-Host ""
Write-Info "Summary:"
Write-Host "  • Features:       $($FEATURES.Count)"
Write-Host "  • Core files:     $((Get-ChildItem -Path lib/src/core -File -Recurse).Count)"
Write-Host "  • Feature files:  $((Get-ChildItem -Path lib/src/features -File -Recurse -ErrorAction SilentlyContinue).Count)"
Write-Host "  • Total files:    $((Get-ChildItem -Path lib/src -File -Recurse).Count)"
Write-Host ""
Write-Info "Documentation: ARCHITECTURE.md"
Write-Host ""
Write-Host "Next: Start implementing your features!"
Write-Host "Run: flutter run"
Write-Host ""
```

## 📝 Save and Commit

Save this as `scripts/setup-windows.ps1` in your repo, then:

```bash
cd ~/Documents/Projects/flutter-clean-architecture
git add scripts/setup-windows.ps1
git commit -m "feat: update Windows script to v4.6 with interactive feature input"
git push origin main
```

## 🎯 Key Features of Windows Version

1. ✅ Same interactive prompts as Unix version
2. ✅ Feature name input (comma-separated)
3. ✅ Creates empty files only
4. ✅ PowerShell-native menus
5. ✅ Colored output (Cyan, Green, Yellow, Red)
6. ✅ Error handling with `$ErrorActionPreference = "Stop"`
7. ✅ Directory and file creation with PowerShell cmdlets
8. ✅ Generates ARCHITECTURE.md

## 🚀 Usage on Windows

```powershell
cd C:\Users\YourName\Projects\your-flutter-app
powershell -ExecutionPolicy Bypass -File path\to\setup-windows.ps1
```

Both scripts now have feature parity! 🎉
