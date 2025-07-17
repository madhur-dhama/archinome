#!/bin/bash

set -e  # Exit on any error

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/madhur-dhama/dotfiles"
REPO_NAME="dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

is_stow_installed() {
    command -v stow &> /dev/null
}

cleanup() {
    log_info "Cleaning up..."
    cd "$ORIGINAL_DIR"
}

# Set up cleanup on exit
trap cleanup EXIT

# Check dependencies
if ! is_stow_installed; then
    log_error "GNU Stow is not installed. Please install it first:"
    echo "  - Arch: sudo pacman -S stow"
    echo "  - Ubuntu/Debian: sudo apt install stow"
    echo "  - macOS: brew install stow"
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    log_error "Git is not installed. Please install git first."
    exit 1
fi

cd ~

# Check if the repository already exists
if [ -d "$REPO_NAME" ]; then
    log_warn "Repository '$REPO_NAME' already exists. Pulling latest changes..."
    cd "$REPO_NAME"
    git pull origin main || git pull origin master || {
        log_error "Failed to pull latest changes"
        exit 1
    }
else
    log_info "Cloning repository..."
    git clone "$REPO_URL" || {
        log_error "Failed to clone the repository"
        exit 1
    }
    cd "$REPO_NAME"
fi

# Remove any existing files that might conflict (fresh install cleanup)
log_info "Removing any existing config files..."
rm -f "$HOME/.bashrc" 2>/dev/null || true
rm -f "$HOME/.config/starship.toml" 2>/dev/null || true
rm -rf "$HOME/.config/kitty" 2>/dev/null || true
rm -rf "$HOME/.config/nvim" 2>/dev/null || true
rm -rf "$HOME/.config/hypr" 2>/dev/null || true
rm -rf "$HOME/.config/ghostty" 2>/dev/null || true

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Apply stow
log_info "Applying stow configuration..."
if stow */; then
    log_info "Dotfiles installation completed successfully!"
else
    log_error "Stow failed. Check for conflicts or missing directories."
    exit 1
fi

# Optional: Source bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    log_info "Sourcing new .bashrc..."
    # Note: This only affects the script's environment, not the current shell
    source "$HOME/.bashrc" || log_warn "Failed to source .bashrc"
fi

log_info "Installation complete"
