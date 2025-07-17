#!/bin/bash

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

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &> /dev/null
}

# Function to check if a package group is installed
is_group_installed() {
    pacman -Qg "$1" &> /dev/null
}

# Function to check if a package exists in repositories
package_exists() {
    local package="$1"
    
    # Check official repos first
    if pacman -Si "$package" &> /dev/null; then
        return 0
    fi
    
    # Check AUR
    if command -v paru &> /dev/null; then
        if paru -Si "$package" &> /dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# Function to install packages if not already installed
install_packages() {
    local packages=("$@")
    local to_install=()
    local not_found=()
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Check which packages need to be installed
    for pkg in "${packages[@]}"; do
        if is_installed "$pkg" || is_group_installed "$pkg"; then
            # Package already installed - do nothing (silent)
            continue
        elif package_exists "$pkg"; then
            to_install+=("$pkg")
        else
            not_found+=("$pkg")
            print_error "Package not found: $pkg"
        fi
    done
    
    # Report packages that weren't found
    if [[ ${#not_found[@]} -gt 0 ]]; then
        print_error "The following packages were not found and will be skipped:"
        for pkg in "${not_found[@]}"; do
            echo "  - $pkg"
        done
    fi
    
    # Install packages that need to be installed
    if [[ ${#to_install[@]} -ne 0 ]]; then
        print_status "Installing: ${to_install[*]}"
        
        if command -v paru &> /dev/null; then
            if ! paru -S --noconfirm "${to_install[@]}"; then
                print_error "Failed to install some packages: ${to_install[*]}"
                return 1
            fi
        else
            print_error "paru is not installed. Cannot install AUR packages."
            return 1
        fi
    fi
}

# Function to install packages with better error handling
install_packages_safe() {
    local packages=("$@")
    local failed=()
    
    for pkg in "${packages[@]}"; do
        if is_installed "$pkg" || is_group_installed "$pkg"; then
            print_success "$pkg is already installed"
            continue
        fi
        
        print_status "Installing $pkg..."
        if paru -S --noconfirm "$pkg"; then
            print_success "$pkg installed successfully"
        else
            print_error "Failed to install $pkg"
            failed+=("$pkg")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_error "Failed to install: ${failed[*]}"
        return 1
    fi
    
    return 0
}