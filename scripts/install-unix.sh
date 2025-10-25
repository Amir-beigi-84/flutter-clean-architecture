
#!/usr/bin/env bash
###############################################################################
# Flutter Clean Architecture - Global Installer
# Makes flutter-clean command available system-wide
###############################################################################
set -eEuo pipefail

INSTALL_DIR="${HOME}/.local/bin"
COMMAND_NAME="flutter-clean"
REPO_URL="https://raw.githubusercontent.com/Amir-beigi-84/flutter-clean-architecture/main/scripts/setup-unix.sh"

# Colors
info()    { printf "\033[36m[INFO]\033[0m %s\n" "$*"; }
success() { printf "\033[32m[ OK ]\033[0m %s\n" "$*"; }
fail()    { printf "\033[31m[FAIL]\033[0m %s\n" "$*" >&2; exit 1; }

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download the script
info "Downloading flutter-clean script..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$REPO_URL" -o "$INSTALL_DIR/$COMMAND_NAME" || fail "Download failed"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$INSTALL_DIR/$COMMAND_NAME" "$REPO_URL" || fail "Download failed"
else
  fail "curl or wget required"
fi

# Make executable
chmod +x "$INSTALL_DIR/$COMMAND_NAME"

# Add to PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  info "Adding $INSTALL_DIR to PATH..."

  # Detect shell
  if [[ -n "${BASH_VERSION:-}" ]]; then
    SHELL_RC="$HOME/.bashrc"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    SHELL_RC="$HOME/.zshrc"
  else
    SHELL_RC="$HOME/.profile"
  fi

  echo "" >> "$SHELL_RC"
  echo "# Flutter Clean Architecture CLI" >> "$SHELL_RC"
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"

  success "Added to PATH in $SHELL_RC"
  info "Run: source $SHELL_RC  (or restart terminal)"
fi

success "✓ Installed! Use: $COMMAND_NAME --auto"
echo ""
echo "Quick commands:"
echo "  flutter-clean --auto                  # Auto-detect everything"
echo "  flutter-clean --state riverpod --auto # Riverpod setup"
echo "  flutter-clean --help                  # Show all options"
