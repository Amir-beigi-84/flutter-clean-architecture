
#!/usr/bin/env bash
###############################################################################
# Flutter Clean Architecture Structure Generator
# Creates folder structure and empty files based on user-provided features
# Version: 4.6 • Updated: 2025-10-25
###############################################################################
set -eEuo pipefail
IFS=$'\n\t'

# ---- Colors and Logging ----
info()    { printf "\033[36m[INFO]\033[0m %s\n" "$*"; }
success() { printf "\033[32m[ OK ]\033[0m %s\n" "$*"; }
warn()    { printf "\033[33m[WARN]\033[0m %s\n" "$*"; }
fail()    { printf "\033[31m[FAIL]\033[0m %s\n" "$*" >&2; exit 1; }

trap 'fail "Script interrupted by user."' INT

# ---- Banner ----
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║   Flutter Clean Architecture Structure Generator          ║
║   Creates empty files for your features                   ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo

# ---- Environment Validation ----
info "Validating environment..."
command -v flutter >/dev/null || fail "Flutter not found in PATH."
command -v dart >/dev/null || fail "Dart not found in PATH."
[[ -f pubspec.yaml ]] || fail "pubspec.yaml not found. Run from project root."

FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -n1 | awk '{print $2}')
success "Flutter detected: $FLUTTER_VERSION"
echo

# ---- Helper Functions ----
confirm() {
  read -rp "$(printf "\033[33m?\033[0m %s [y/N]: " "$1")" ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

# ---- Collect Configuration ----
read -rp "$(printf "\033[36m→\033[0m App Display Name (press Enter to keep current): ")" APP_NAME
APP_NAME=${APP_NAME:-$(awk -F: '/^name:/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' pubspec.yaml)}

echo
info "Select state management solution:"
PS3="$(printf "\033[36m→\033[0m Choice (1-4): ")"
select STATE_MGMT in bloc riverpod provider getx; do
  [[ -n "$STATE_MGMT" ]] && break
  echo "Invalid selection. Try again."
done

echo
info "Select navigation solution:"
PS3="$(printf "\033[36m→\033[0m Choice (1-2): ")"
select ROUTER in none go_router; do
  [[ -n "$ROUTER" ]] && break
  echo "Invalid selection. Try again."
done

echo
info "Select dependency profile:"
PS3="$(printf "\033[36m→\033[0m Choice (1-3): ")"
select PROFILE in minimal standard full; do
  [[ -n "$PROFILE" ]] && break
  echo "Invalid selection. Try again."
done

# ---- Collect Feature Names ----
echo
info "Enter your feature names (comma-separated)"
info "Example: auth,profile,settings,dashboard"
echo
read -rp "$(printf "\033[36m→\033[0m Features: ")" FEATURES_INPUT

# Parse and validate features
IFS=',' read -ra FEATURES <<< "$FEATURES_INPUT"
# Trim whitespace and convert to lowercase
for i in "${!FEATURES[@]}"; do
  FEATURES[$i]=$(echo "${FEATURES[$i]}" | xargs | tr '[:upper:]' '[:lower:]')
done

# Remove empty entries
FEATURES=("${FEATURES[@]// /}")

if [[ ${#FEATURES[@]} -eq 0 ]] || [[ -z "${FEATURES[0]}" ]]; then
  fail "No features provided. Please enter at least one feature name."
fi

echo
confirm "Skip dependency installation (structure only)?" && SKIP_INSTALL=true || SKIP_INSTALL=false

# ---- Configuration Summary ----
echo
info "Configuration Summary:"
printf "  ✓ App Name:     %s\n" "$APP_NAME"
printf "  ✓ State Mgmt:   %s\n" "$STATE_MGMT"
printf "  ✓ Router:       %s\n" "$ROUTER"
printf "  ✓ Profile:      %s\n" "$PROFILE"
printf "  ✓ Features:     %s\n" "${FEATURES[*]}"
printf "  ✓ Skip Install: %s\n" "$SKIP_INSTALL"
echo

confirm "Proceed with structure generation?" || { warn "Cancelled by user."; exit 0; }

# ---- Dependency Resolution ----
deps=(get_it dio equatable)
case "$STATE_MGMT" in
  bloc) deps+=(flutter_bloc);;
  riverpod) deps+=(flutter_riverpod);;
  provider) deps+=(provider);;
  getx) deps+=(get);;
esac

case "$PROFILE" in
  minimal) deps+=(fpdart);;
  standard) deps+=(connectivity_plus pretty_dio_logger fpdart);;
  full) deps+=(connectivity_plus pretty_dio_logger shared_preferences flutter_secure_storage fpdart json_annotation);;
esac
[[ "$ROUTER" == "go_router" ]] && deps+=(go_router)

# ---- Installation Phase ----
echo
if [[ "$SKIP_INSTALL" == false ]]; then
  info "Installing ${#deps[@]} dependencies..."
  dart pub add "${deps[@]}" 2>&1 | grep -v "Resolving dependencies" || true
  success "Dependencies installed."

  case "$PROFILE" in
    full)
      info "Installing dev dependencies..."
      dart pub add -d flutter_lints build_runner json_serializable 2>&1 | grep -v "Resolving dependencies" || true
      ;;
    standard)
      dart pub add -d flutter_lints 2>&1 | grep -v "Resolving dependencies" || true
      ;;
  esac
else
  warn "Skipped dependency installation."
fi

# ---- CRITICAL: Create ALL directories FIRST ----
echo
info "Creating directory structure..."

# Core directories
mkdir -p lib/src/core/{constants,network,error,theme,di,usecase,utils}
[[ "$ROUTER" == "go_router" ]] && mkdir -p lib/src/core/router

# Feature directories
for feature in "${FEATURES[@]}"; do
  [[ -z "$feature" ]] && continue

  mkdir -p "lib/src/features/$feature/domain/"{entities,repositories,usecases}
  mkdir -p "lib/src/features/$feature/data/"{models,datasources,repositories}

  case "$STATE_MGMT" in
    bloc)
      mkdir -p "lib/src/features/$feature/presentation/"{bloc,pages,widgets}
      ;;
    riverpod)
      mkdir -p "lib/src/features/$feature/presentation/"{providers,pages,widgets}
      ;;
    provider)
      mkdir -p "lib/src/features/$feature/presentation/"{notifiers,pages,widgets}
      ;;
    getx)
      mkdir -p "lib/src/features/$feature/presentation/"{controllers,pages,widgets}
      ;;
  esac
done

success "Directory structure created."

# ---- Create Core Files (NOW directories exist) ----
echo
info "Creating core files..."

touch lib/src/core/constants/app_constants.dart
touch lib/src/core/error/failures.dart
touch lib/src/core/error/exceptions.dart
touch lib/src/core/usecase/usecase.dart
touch lib/src/core/theme/app_theme.dart
touch lib/src/core/di/injection.dart

if [[ "$PROFILE" != "minimal" ]]; then
  touch lib/src/core/network/network_info.dart
  touch lib/src/core/network/dio_client.dart
fi

[[ "$ROUTER" == "go_router" ]] && touch lib/src/core/router/app_router.dart

success "Core files created."

# ---- Generate Feature Files ----
echo
info "Generating feature files..."

for feature in "${FEATURES[@]}"; do
  [[ -z "$feature" ]] && continue

  info "  → Creating files for: $feature"

  # Domain layer
  touch "lib/src/features/$feature/domain/entities/${feature}_entity.dart"
  touch "lib/src/features/$feature/domain/repositories/${feature}_repository.dart"
  touch "lib/src/features/$feature/domain/usecases/get_${feature}.dart"

  # Data layer
  touch "lib/src/features/$feature/data/models/${feature}_model.dart"
  touch "lib/src/features/$feature/data/datasources/${feature}_remote_data_source.dart"
  touch "lib/src/features/$feature/data/datasources/${feature}_local_data_source.dart"
  touch "lib/src/features/$feature/data/repositories/${feature}_repository_impl.dart"

  # Presentation layer
  touch "lib/src/features/$feature/presentation/pages/${feature}_page.dart"
  touch "lib/src/features/$feature/presentation/widgets/${feature}_widget.dart"

  case "$STATE_MGMT" in
    bloc)
      touch "lib/src/features/$feature/presentation/bloc/${feature}_bloc.dart"
      touch "lib/src/features/$feature/presentation/bloc/${feature}_event.dart"
      touch "lib/src/features/$feature/presentation/bloc/${feature}_state.dart"
      ;;
    riverpod)
      touch "lib/src/features/$feature/presentation/providers/${feature}_provider.dart"
      ;;
    provider)
      touch "lib/src/features/$feature/presentation/notifiers/${feature}_notifier.dart"
      ;;
    getx)
      touch "lib/src/features/$feature/presentation/controllers/${feature}_controller.dart"
      ;;
  esac

  success "  ✓ Feature '$feature' files created"
done

# ---- App Entry Points ----
touch lib/src/app.dart
touch lib/main.dart

# ---- Analysis Options ----
cat > analysis_options.yaml <<'EOF'
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
    require_trailing_commas: true
    always_use_package_imports: true
    prefer_const_constructors: true
    avoid_print: true
EOF

# ---- Architecture Documentation ----
cat > ARCHITECTURE.md <<EOF
# $APP_NAME - Architecture

**State Management:** $STATE_MGMT
**Router:** $ROUTER
**Profile:** $PROFILE

## Features

$(for feature in "${FEATURES[@]}"; do echo "- **$feature**"; done)

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

\`\`\`
lib/src/
├── core/
│   ├── constants/
│   ├── di/
│   ├── error/
│   ├── network/
│   ├── theme/
│   └── usecase/
├── features/
$(for feature in "${FEATURES[@]}"; do echo "│   ├── $feature/"; done)
├── app.dart
└── main.dart
\`\`\`

## Next Steps

1. Implement entities in \`domain/entities/\`
2. Define repository contracts in \`domain/repositories/\`
3. Create use cases in \`domain/usecases/\`
4. Implement models and data sources in \`data/\`
5. Build UI in \`presentation/\`
6. Configure DI in \`core/di/injection.dart\`
7. Run: \`flutter run\`
EOF

# ---- Final Summary ----
echo
success "✓ Project structure generated successfully!"
echo
info "Summary:"
printf "  • Features:       %d\n" "${#FEATURES[@]}"
printf "  • Core files:     %d\n" "$(find lib/src/core -type f 2>/dev/null | wc -l)"
printf "  • Feature files:  %d\n" "$(find lib/src/features -type f 2>/dev/null | wc -l)"
printf "  • Total files:    %d\n" "$(find lib/src -type f 2>/dev/null | wc -l)"
echo
info "Documentation: ARCHITECTURE.md"
echo
echo "Next: Start implementing your features!"
echo "Run: flutter run"
echo
