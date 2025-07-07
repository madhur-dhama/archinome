#!/bin/bash

# Print the logo
print_logo() {
    cat << "EOF"
    
    █████╗ ██████╗  ██████╗██╗  ██╗███╗   ██╗ ██████╗ ███╗   ███╗███████╗
   ██╔══██╗██╔══██╗██╔════╝██║  ██║████╗  ██║██╔═══██╗████╗ ████║██╔════╝
   ███████║██████╔╝██║     ███████║██╔██╗ ██║██║   ██║██╔████╔██║█████╗  
   ██╔══██║██╔══██╗██║     ██╔══██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══╝  
   ██║  ██║██║  ██║╚██████╗██║  ██║██║ ╚████║╚██████╔╝██║ ╚═╝ ██║███████╗
   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
     Archnome - Arch Linux System Crafting Tool      
            by madhur                         


EOF
}

# Parse command line arguments
DEV_ONLY=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --dev-only) DEV_ONLY=true; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
done

# Clear screen and show logo
clear
print_logo

# Exit on any error
set -e

# Source utility functions
source utils.sh

# Source the package list
if [ ! -f "packages.conf" ]; then
  echo "Error: packages.conf not found!"
  exit 1
fi

source packages.conf

if [[ "$DEV_ONLY" == true ]]; then
  echo "Starting development-only setup..."
else
  echo "Starting full system setup..."
fi

# Update the system first
echo "Updating system..."
sudo pacman -Syu --noconfirm

# Install yay AUR helper if not present
if ! command -v yay &> /dev/null; then
  echo "Installing yay AUR helper..."
  sudo pacman -S --needed git base-devel --noconfirm
  if [[ ! -d "yay" ]]; then
    echo "Cloning yay repository..."
  else
    echo "yay directory already exists, removing it..."
    rm -rf yay
  fi

  git clone https://aur.archlinux.org/yay.git

  cd yay
  echo "building yay.... yaaaaayyyyy"
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
else
  echo "yay is already installed"
fi

# Install packages by category
if [[ "$DEV_ONLY" == true ]]; then
  # Only install essential development packages
  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"
  
  echo "Installing development tools..."
  install_packages "${DEV_TOOLS[@]}"
else
  # Install all packages
  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"
  
  echo "Installing development tools..."
  install_packages "${DEV_TOOLS[@]}"
  
  echo "Installing system maintenance tools..."
  install_packages "${MAINTENANCE[@]}"
  
  echo "Installing desktop environment..."
  install_packages "${DESKTOP[@]}"
  
  echo "Installing desktop environment..."
  install_packages "${OFFICE[@]}"
  
  echo "Installing media packages..."
  install_packages "${MEDIA[@]}"
  
  echo "Installing fonts..."
  install_packages "${FONTS[@]}"
  
  # Enable services
  echo "Configuring services..."
  for service in "${SERVICES[@]}"; do
    if ! systemctl is-enabled "$service" &> /dev/null; then
      echo "Enabling $service..."
      sudo systemctl enable "$service"
    else
      echo "$service is already enabled"
    fi
  done
  
  # Install gnome specific things to make it like a tiling WM
  echo "Installing Gnome extensions..."
  . gnome/gnome-extensions.sh
  echo "Setting Gnome hotkeys..."
  . gnome/gnome-hotkeys.sh
  echo "Configuring Gnome..."
  . gnome/gnome-settings.sh
  
  # Some programs just run better as flatpaks. Like zen browser/mission center
  echo "Installing flatpaks (like zen browser and mission center)"
  . install-flatpaks.sh
fi

echo "Setup complete! You may want to reboot your system."
