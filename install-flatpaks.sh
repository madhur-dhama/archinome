#!/bin/bash
set -e

FLATPAKS=(
  "app.zen_browser.zen"
  "io.missioncenter.MissionCenter"
  "com.visualstudio.code"
  "org.onlyoffice.desktopeditors"
)

for pak in "${FLATPAKS[@]}"; do
  if ! flatpak list | grep -i "$pak" &> /dev/null; then
    echo "Installing Flatpak: $pak"
    flatpak install --noninteractive "$pak"
  else
    echo "Flatpak already installed: $pak"
  fi
done