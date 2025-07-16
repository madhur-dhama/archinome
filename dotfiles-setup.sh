#!/bin/bash

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/madhur-dhama/dotfiles"
REPO_NAME="dotfiles"

is_stow_installed() {
  command -v stow &> /dev/null
}

if ! is_stow_installed; then
  echo "Install stow first"
  exit 1
fi

cd ~

# Check if the repository already exists
if [ -d "$REPO_NAME" ]; then
  echo "Repository '$REPO_NAME' already exists. Skipping clone"
else
  git clone "$REPO_URL"
fi

# Check if the clone was successful
if [ $? -eq 0 ]; then
  cd "$REPO_NAME"

  # Remove pre-existing config files/directories before stow
  echo "Removing pre-existing config files..."
  rm -f  $HOME/.bashrc
  rm -rf $HOME/.config/kitty
  rm -rf $HOME/.config/nvim
  rm -rf $HOME/.config/hypr
  rm -f  $HOME/.config/starship.toml
  

  # Now apply stow
  stow */
else
  echo "Failed to clone the repository."
  exit 1
fi

