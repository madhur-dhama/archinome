# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Seting dark theme
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
# Seting wallpaper 
#echo "setting wallpaper to ${SCRIPT_DIR}/wallpaper.jpeg"
#gsettings set org.gnome.desktop.background picture-uri-dark "file://${SCRIPT_DIR}/wallpaper.jpg"
#gsettings set org.gnome.desktop.background picture-options 'zoom'

# Diaplay scale to 125%
#gsettings set org.gnome.desktop.interface text-scaling-factor 1.25

# Enable ulauncher at startup 
systemctl --user enable --now ulauncher
