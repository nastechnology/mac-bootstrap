#!/usr/bin/env bash
#
# This bootstraps Puppet on Mac OS X 10.8 and 10.7.
#
# Optional environmental variables:
#   - FACTER_PACKAGE_URL: The URL to the Facter package to install.
#   - HIERA_PACKAGE_URL:  The URL to the Hiera package to install.
#   - PUPPET_PACKAGE_URL: The URL to the Puppet package to install.
#
set -e

#--------------------------------------------------------------------
# Modifiable variables, please set them via environmental variables.
#--------------------------------------------------------------------
FACTER_PACKAGE_URL=${FACTER_PACKAGE_URL:-"http://downloads.puppetlabs.com/mac/facter-2.2.0.dmg"}
HIERA_PACKAGE_URL=${HIERA_PACKAGE_URL:-"http://downloads.puppetlabs.com/mac/hiera-1.3.4.dmg"}
PUPPET_PACKAGE_URL=${PUPPET_PACKAGE_URL:-"http://downloads.puppetlabs.com/mac/puppet-3.7.3.dmg"}

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
  local dmg_path=$(mktemp -t ${name}-dmg)

  echo "Installing: ${name}"

  # Download the package into the temporary directory
  echo "-- Downloading DMG..."
  curl -L -o ${dmg_path} ${url} 2>/dev/null

  # Mount it
  echo "-- Mounting DMG..."
  local plist_path=$(mktemp -t puppet-bootstrap)
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

# Install Puppet and Facter
install_dmg "Facter" ${FACTER_PACKAGE_URL}
install_dmg "Hiera" ${HIERA_PACKAGE_URL}
install_dmg "Puppet" ${PUPPET_PACKAGE_URL}


echo "-- Stop puppetlabs daemon..."
sudo launchctl unload /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo "Launchd has stopped puppetlabs daemon"

echo "-- Remove SSL files..."
sudo rm -Rf /etc/puppet/ssl
echo "SSL files removed"

echo "-- Replace old server with new server..."
sed -i '' "s/server = puppet.nacswildcats.org/server = puppet01.nacswildcats.org/g" /etc/puppet/puppet.cfg
echo "New server in place"

echo "-- Make Launchd aware of new daemon..."
sudo launchctl load -w /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo "Launchd is now aware of puppetlabs daemon"