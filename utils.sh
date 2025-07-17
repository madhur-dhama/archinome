#!/bin/bash

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
            continue
        elif package_exists "$pkg"; then
            to_install+=("$pkg")
        else
            not_found+=("$pkg")
            echo "ERROR: Package not found: $pkg"
        fi
    done
    
    # Report packages that weren't found
    if [[ ${#not_found[@]} -gt 0 ]]; then
        echo "ERROR: The following packages were not found and will be skipped:"
        for pkg in "${not_found[@]}"; do
            echo "  - $pkg"
        done
    fi
    
    # Install packages that need to be installed
    if [[ ${#to_install[@]} -ne 0 ]]; then
        echo "Installing: ${to_install[*]}"
        
        if command -v paru &> /dev/null; then
            if ! paru -S --noconfirm "${to_install[@]}"; then
                echo "ERROR: Failed to install some packages: ${to_install[*]}"
                return 1
            fi
        else
            echo "ERROR: paru is not installed. Cannot install AUR packages."
            return 1
        fi
    fi
}

# Function to install packages with individual error handling
install_packages_safe() {
    local packages=("$@")
    local failed=()
    
    for pkg in "${packages[@]}"; do
        if is_installed "$pkg" || is_group_installed "$pkg"; then
            echo "$pkg is already installed"
            continue
        fi
        
        echo "Installing $pkg..."
        if paru -S --noconfirm "$pkg"; then
            echo "$pkg installed successfully"
        else
            echo "ERROR: Failed to install $pkg"
            failed+=("$pkg")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "ERROR: Failed to install: ${failed[*]}"
        return 1
    fi
    
    return 0
}
