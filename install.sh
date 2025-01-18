#!/bin/bash
set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Installation directories
readonly INSTALL_DIR="$HOME/.devops-utils"
readonly BIN_DIR="$HOME/bin"
readonly SCRIPT_NAME="devops"

# Fancy output functions
print_banner() {
    echo -e "${CYAN}"
    echo '╔═══════════════════════════════════════════╗'
    echo '║           DevOps Utils Installer          ║'
    echo '╚═══════════════════════════════════════════╝'
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}$1${NC}"
}

log_step() {
    echo -e "${CYAN}$1${NC}"
}

# Detect shell (zsh or bash)
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "bash"  # Default to bash if unsure
    fi
}

# Setup shell configuration
setup_shell() {
    local shell_type=$(detect_shell)
    local shell_config

    if [ "$shell_type" = "zsh" ]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi

    log_step "Configuring shell environment ($shell_type)..."

    # Add to PATH if not already there
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$shell_config"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_config"
        log_success "Added bin directory to PATH in $shell_config"
    else
        log_info "PATH already configured in $shell_config"
    fi
}

install_devops_utils() {
    print_banner

    log_step "Preparing installation directories..."
    # Create necessary directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"

    # Clone the repository
    if [ -d "$INSTALL_DIR/.git" ]; then
        log_step "Updating existing installation... $INSTALL_DIR"
        git -C "$INSTALL_DIR" pull
    else
        log_step "Performing fresh installation... $INSTALL_DIR"
        # Redirect git output to hide verbose clone messages
        git clone https://github.com/m1981/devops-utils.git "$INSTALL_DIR" 2>&1 | grep -v "Receiving objects" | grep -v "Resolving deltas" || true
    fi

    log_step "Creating executable script..."
    # Create symlink from the actual script to bin directory
    ln -sf "$INSTALL_DIR/scripts/devops.sh" "$BIN_DIR/devops"
    chmod +x "$INSTALL_DIR/scripts/devops.sh"

    if [ -f "$BIN_DIR/devops" ]; then
        log_success "Successfully created executable at $BIN_DIR/devops"
    else
        log_error "Failed to create executable script"
        exit 1
    fi

    # Setup shell configuration
    setup_shell

    echo
    log_success "Installation completed successfully! 🎉"
    log_info "To start using DevOps Utils, either:"
    echo -e "${YELLOW}  1. Restart your terminal${NC}"
    echo -e "${YELLOW}  2. Run: ${CYAN}source ~/.$(detect_shell)rc${NC}"
    echo
    log_info "Then you can use '${CYAN}devops${NC}' command from anywhere"
    echo -e "${BLUE}Try: ${CYAN}devops help${NC} to get started"
    echo
}

# Check for required tools
check_dependencies() {
    log_step "Checking dependencies..."
    local missing_deps=()

    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi

    if ! command -v docker >/dev/null 2>&1; then
        missing_deps+=("docker")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_warning "Please install the missing dependencies and try again"
        exit 1
    fi

    log_success "All dependencies found"
}

main() {
    # Check if running with sudo
    if [ "$(id -u)" = "0" ]; then
        log_error "This script should not be run with sudo"
        exit 1
    fi

    check_dependencies
    install_devops_utils
}

main
