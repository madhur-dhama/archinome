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
    echo "  - Ubuntu/Debian: sudo apt install stow"
    echo "  - macOS: brew install stow"
    echo "  - Arch: sudo pacman -S stow"
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

# Create backup directory with timestamp
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to backup and remove files
backup_and_remove() {
    local file="$1"
    if [ -e "$file" ] || [ -L "$file" ]; then
        log_info "Backing up $file to $BACKUP_DIR"
        cp -r "$file" "$BACKUP_DIR/" 2>/dev/null || true
        rm -rf "$file"
    fi
}

# Remove/backup pre-existing config files/directories before stow
log_info "Backing up and removing pre-existing config files..."
backup_and_remove "$HOME/.bashrc"
backup_and_remove "$HOME/.config/kitty"
backup_and_remove "$HOME/.config/nvim"
backup_and_remove "$HOME/.config/starship.toml"
backup_and_remove "$HOME/.config/hypr"

# Check if there are any stow packages to install
if [ -z "$(find . -maxdepth 1 -type d -name "*" ! -name "." ! -name ".git" ! -name ".github" 2>/dev/null)" ]; then
    log_error "No stow packages found in the repository"
    exit 1
fi

# Apply stow
log_info "Applying stow configuration..."
if stow --verbose=2 */; then
    log_info "Dotfiles installation completed successfully!"
    log_info "Backup created at: $BACKUP_DIR"
    
    # Check if backup directory is empty and remove it
    if [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        rmdir "$BACKUP_DIR"
        log_info "No files were backed up, backup directory removed"
    fi
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

log_info "Installation complete! You may need to restart your terminal or run 'source ~/.bashrc'"
