#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Source utils.sh from parent directory
source "$SCRIPT_DIR/../utils.sh"

install_packages python-pipx gnome-shell-extensions

# Install gnome-extensions-cli only if not already installed
if ! command -v ~/.local/bin/gext &> /dev/null; then
  pipx install gnome-extensions-cli --system-site-packages
fi

EXTENSIONS=(
  "tactile@lundal.io"
  "just-perfection-desktop@just-perfection"
  "blur-my-shell@aunetx"
  "space-bar@luchrioh"
  "undecorate@sun.wxg@gmail.com"
  "tophat@fflewddur.github.io"
  "switcher@landau.fi"
)

for ext in "${EXTENSIONS[@]}"; do
  if ! ~/.local/bin/gext list | grep "$ext" &> /dev/null; then
    echo "Installing extension: $ext"
    ~/.local/bin/gext install "$ext"
  else
    echo "Extension already installed: $ext"
  fi
done

# Now load settings from dconf file
dconf load /org/gnome/shell/extensions/ < "$SCRIPT_DIR/gnome-settings.dconf"
