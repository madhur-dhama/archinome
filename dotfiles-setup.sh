#!/bin/bash

set -e  # Exit immediately on error

REPO_URL="https://github.com/madhur-dhama/dotfiles"
REPO_NAME="dotfiles"
REPO_DIR="$HOME/$REPO_NAME"

# Required dotfiles (update this list as needed)
DOTFILES=("bashrc" "nvim" "ghostty" "starship")

# Check if stow is installed
is_stow_installed() {
  command -v stow &> /dev/null
}

# Check if git is installed
is_git_installed() {
  command -v git &> /dev/null
}

# Remove conflicting files/directories
remove_conflicts() {
  echo "Removing conflicting files..."

  [ -f "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
  [ -d "$HOME/.config/nvim" ] && rm -rf "$HOME/.config/nvim"
  [ -f "$HOME/.config/starship.toml" ] && rm "$HOME/.config/starship.toml"
}

# Check for dependencies
if ! is_git_installed; then
  echo "Git is not installed. Please install it first."
  exit 1
fi

if ! is_stow_installed; then
  echo "Stow is not installed. Please install it first."
  exit 1
fi

# Clone the dotfiles repo if it doesn't exist
cd "$HOME"
if [ -d "$REPO_NAME" ]; then
  echo "Repository '$REPO_NAME' already exists. Skipping clone."
else
  git clone "$REPO_URL"
fi

# Go into the repo
cd "$REPO_DIR"

# Remove old conflicting files
remove_conflicts

# Stow the dotfiles
for dir in "${DOTFILES[@]}"; do
  if [ -d "$dir" ]; then
    echo "Stowing $dir..."
    stow "$dir"
  else
    echo "Warning: '$dir' directory not found in the repo."
  fi
done

echo "✅ Dotfiles setup complete!"

