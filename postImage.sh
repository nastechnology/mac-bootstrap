#!/usr/bin/env bash

set -e

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT.
#--------------------------------------------------------------------
if [ "$EUID" -ne "0" ]; then
echo "This script must be run as root." >&2
  exit 1
fi

# This function will download a DMG from a URL, mount it, find
# the `pkg` in it, install that pkg, and unmount the package.
function install_dmg() {
  local name="$1"
  local url="$2"
  local dmg_path=$(mktemp -t ${name}_dmg)

  echo "Installing: ${name}"

  # Download the package into the temporary directory
  echo "-- Downloading DMG..."
  curl -L -o ${dmg_path} ${url} 2>/dev/null

  chmod 777 ${dmg_path}

  # Mount it
  echo "-- Mounting DMG..."
  local plist_path=$(mktemp -t nacs_mac_bootstrap)
  hdiutil attach -plist ${dmg_path} > ${plist_path}
  mount_point=$(grep -E -o '/Volumes/[-.a-zA-Z0-9]+' ${plist_path})

  # Install. It will be the only pkg in there, so just find any pkg
  echo "-- Installing pkg..."
  pkg_path=$(find ${mount_point} -name '*.pkg' -mindepth 1 -maxdepth 1)
  installer -pkg ${pkg_path} -target / >/dev/null

  # Unmount
  echo "-- Unmounting and ejecting DMG..."
  hdiutil eject ${mount_point} >/dev/null
}


# Download FusionInventory-Agent and install
install_dmg "FusionInventory_Agent" "http://tech.napoleonareaschools.org/NACS-FIA.dmg"
# Download MunkiWebAdmin and install
install_dmg "MunkiWebAdmin" "http://tech.napoleonareaschools.org/munkiwebadmin.dmg"