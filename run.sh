#!/bin/bash

# Print the logo
print_logo() {
    cat << "EOF"

   ▄████████    ▄████████  ▄████████    ▄█    █▄     ▄█  ███▄▄▄▄    ▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████ 
  ███    ███   ███    ███ ███    ███   ███    ███   ███  ███▀▀▀██▄ ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ 
  ███    ███   ███    ███ ███    █▀    ███    ███   ███▌ ███   ███ ███    ███ ███   ███   ███   ███    █▀  
  ███    ███  ▄███▄▄▄▄██▀ ███         ▄███▄▄▄▄███▄▄ ███▌ ███   ███ ███    ███ ███   ███   ███  ▄███▄▄▄     
▀███████████ ▀▀███▀▀▀▀▀   ███        ▀▀███▀▀▀▀███▀  ███▌ ███   ███ ███    ███ ███   ███   ███ ▀▀███▀▀▀     
  ███    ███ ▀███████████ ███    █▄    ███    ███   ███  ███   ███ ███    ███ ███   ███   ███   ███    █▄  
  ███    ███   ███    ███ ███    ███   ███    ███   ███  ███   ███ ███    ███ ███   ███   ███   ███    ███ 
  ███    █▀    ███    ███ ████████▀    ███    █▀    █▀    ▀█   █▀   ▀██████▀   ▀█   ███   █▀    ██████████ 
               ███    ███                                                                                                                                                       

                                         Arch Linux System Crafting Tool      
                                               by: madhur dhama                        


EOF
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_error "AUR packages must be built as a regular user."
        exit 1
    fi
}

# Function to check required files
check_dependencies() {
    local missing_files=()
    
    if [[ ! -f "utils.sh" ]]; then
        missing_files+=("utils.sh")
    fi
    
    if [[ ! -f "packages.conf" ]]; then
        missing_files+=("packages.conf")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files: ${missing_files[*]}"
        exit 1
    fi
}

# Function to install paru with better error handling
install_paru() {
    if command -v paru &> /dev/null; then
        print_success "paru is already installed"
        return 0
    fi
    
    print_status "Installing paru AUR helper..."
    
    # Install dependencies
    if ! sudo pacman -S --needed git base-devel --noconfirm; then
        print_error "Failed to install paru dependencies"
        exit 1
    fi
    
    # Create temporary directory for building
    local temp_dir=$(mktemp -d)
    local original_dir=$(pwd)
    
    # Cleanup function
    cleanup() {
        cd "$original_dir"
        rm -rf "$temp_dir"
    }
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    cd "$temp_dir"
    
    print_status "Cloning paru repository..."
    if ! git clone https://aur.archlinux.org/paru.git; then
        print_error "Failed to clone paru repository"
        exit 1
    fi
    
    cd paru
    print_status "Building paru..."
    if ! makepkg -si --noconfirm; then
        print_error "Failed to build paru"
        exit 1
    fi
    
    print_success "paru installed successfully"
}

# Parse command line arguments
DEV_ONLY=false
HELP=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dev-only) 
            DEV_ONLY=true
            shift 
            ;;
        -h|--help)
            HELP=true
            shift
            ;;
        *) 
            print_error "Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1 
            ;;
    esac
done

# Show help if requested
if [[ "$HELP" == true ]]; then
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --dev-only    Install only development packages
    -h, --help    Show this help message

Examples:
    $0              # Full system setup
    $0 --dev-only   # Development-only setup
EOF
    exit 0
fi

# Clear screen and show logo
clear
print_logo

# Exit on any error
set -e

# Perform initial checks
check_root
check_dependencies

# Source utility functions
if ! source utils.sh; then
    print_error "Failed to source utils.sh"
    exit 1
fi

# Source the package list
if ! source packages.conf; then
    print_error "Failed to source packages.conf"
    exit 1
fi

if [[ "$DEV_ONLY" == true ]]; then
    print_status "Starting development-only setup..."
else
    print_status "Starting full system setup..."
fi

# Update the system first
print_status "Updating system..."
if ! sudo pacman -Syu --noconfirm; then
    print_error "Failed to update system"
    exit 1
fi

# Install paru AUR helper
install_paru

# Install packages by category
if [[ "$DEV_ONLY" == true ]]; then
    # Only install essential development packages
    print_status "Installing system utilities..."
    install_packages "${SYSTEM_UTILS[@]}"
    
    print_status "Installing development tools..."
    install_packages "${DEV_TOOLS[@]}"
else
    # Install all packages
    print_status "Installing system utilities..."
    install_packages "${SYSTEM_UTILS[@]}"
    
    print_status "Installing development tools..."
    install_packages "${DEV_TOOLS[@]}"
    
    print_status "Installing system maintenance tools..."
    install_packages "${MAINTENANCE[@]}"
    
    #print_status "Installing desktop environment..."
    #install_packages "${DESKTOP[@]}"
    
    print_status "Installing media packages..."
    install_packages "${MEDIA[@]}"
    
    print_status "Installing fonts..."
    install_packages "${FONTS[@]}"
    
    # Enable services
    #print_status "Configuring services..."
    #for service in "${SERVICES[@]}"; do
    #    if ! systemctl is-enabled "$service" &> /dev/null; then
    #        print_status "Enabling $service..."
    #        sudo systemctl enable "$service"
    #    else
    #        print_success "$service is already enabled"
    #    fi
    #done
    
    # Install gnome specific things to make it like a tiling WM
    if [[ -f "gnome/gnome-extensions.sh" ]]; then
        print_status "Installing Gnome extensions..."
        source gnome/gnome-extensions.sh
    fi
    
    if [[ -f "gnome/gnome-binds.sh" ]]; then
        print_status "Setting Gnome keybinds..."
        source gnome/gnome-binds.sh
    fi
    
    if [[ -f "gnome/gnome-settings.sh" ]]; then
        print_status "Configuring Gnome..."
        source gnome/gnome-settings.sh
    fi
    
    # Some programs just run better as flatpaks. Like zen browser/mission center
    if [[ -f "install-flatpaks.sh" ]]; then
        print_status "Installing flatpaks (like zen browser and mission center)"
        source install-flatpaks.sh
    fi
fi

print_success "Setup complete! You may want to reboot your system."
