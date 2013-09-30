#!/usr/bin/env bash

HOSTNAME=$1

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

echo "-- Change host name..."
scutil --set HostName ${HOSTNAME}
echo "Changed hostname to ${HOSTNAME}"


# Download FusionInventory-Agent and install
install_dmg "FusionInventory_Agent" "http://tech.napoleonareaschools.org/NACS-FIA.dmg"
# Download MunkiWebAdmin and install
install_dmg "MunkiWebAdmin" "http://tech.napoleonareaschools.org/munkiwebadmin.dmg"

# Download puppet file and run to install puppet
curl -k -O https://raw.github.com/nastechnology/mac-bootstrap/master/puppet.sh

chmod +x ./puppet.sh

sudo ./puppet.sh

rm ./puppet.sh

echo "-- Create Puppet Group..."
sudo puppet resource group puppet ensure=present
echo "Created Puppet Group"

echo "-- Create Puppet User..."
sudo puppet resource user puppet ensure=present gid=puppet shell='/sbin/nologin'
echo "Created Puppet User"

echo "-- Get LaunchDaemon File..."
curl -k -O http://tech.napoleonareaschools.org/com.puppetlabs.puppet.plist >  /Library/LaunchDaemons/com.puppetlabs.puppet.plist

echo "-- Set permissions on launchdaemon file..."
sudo chown root:wheel /Library/LaunchDaemons/com.puppetlabs.puppet.plist  
sudo chmod 644 /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo "Permissions are now set"

echo "-- Write puppet configuration file..."
echo "[main]" > /etc/puppet/puppet.conf
echo "server = puppet.nas.local" >> /etc/puppet/puppet.conf
echo "pluginsync = true" >> /etc/puppet/puppet.conf
echo "" >> /etc/puppet/puppet.conf
echo "[agent]" >> /etc/puppet/puppet.conf
echo "runinterval = 1800" >> /etc/puppet/puppet.conf
echo "certname = ${HOSTNAME}.nas.local" >> /etc/puppet/puppet.conf
echo "report = true" >> /etc/puppet/puppet.conf
echo "Done writing configuration file"

echo "-- Make Launchd aware of new daemon..."
sudo launchctl load -w /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo "Launchd is now aware of puppetlabs daemon"

echo "Don't forget to add the inventory tag to /opt/fusioninventory-agent/agent.cfg"
echo "Then reboot you device"
