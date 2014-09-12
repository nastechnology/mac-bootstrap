#!/usr/bin/env bash

HOSTNAME=$1
TAG=$2

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

echo "-- Change computer name"
scutil --set ComputerName ${HOSTNAME}
echo "Changed computer name to ${HOSTNAME}"

echo "-- Change bonjour hostname..."
scutil --set LocalHostName ${HOSTNAME}
echo "Changed bonjour hostname to ${HOSTNAME}"

# Download FusionInventory-Agent and install
install_dmg "FusionInventory_Agent" "http://tech.napoleonareaschools.org/NACS-FIA.dmg"
# Download MunkiWebAdmin and install
#install_dmg "MunkiWebAdmin" "http://tech.napoleonareaschools.org/munkiwebadmin_scripts-2013.11.20.dmg"

# Download puppet file and run to install puppet
curl -k -O https://raw.githubusercontent.com/nastechnology/mac-bootstrap/master/puppetStudents.sh
# Change execute mode on puppet.sh
chmod +x ./puppetStudents.sh
# Install Ppuppet
sudo ./puppetStudents.sh
# Remove the puppet.sh file
rm ./puppet.sh

echo "-- Create Puppet Group..."
sudo puppet resource group puppet ensure=present
echo "Created Puppet Group"

echo "-- Create Puppet User..."
sudo puppet resource user puppet ensure=present gid=puppet shell='/sbin/nologin'
echo "Created Puppet User"

# Create Directory and new.txt file for first puppet run
mkdir /opt/NACSManage

touch /opt/NACSManage/new.txt


# Hide all users from the loginwindow with uid below 500, which will include the puppet user
defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool YES

echo "-- Write LaunchDaemon File..."
echo '<?xml version="1.0" encoding="UTF-8"?>' > /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '<plist version="1.0">' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '<dict>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>EnvironmentVariables</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <dict>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <key>PATH</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>/sbin:/usr/sbin:/bin:/usr/bin</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <key>RUBYLIB</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>/usr/lib/ruby/site_ruby/1.8/</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        </dict>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>Label</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <string>com.puppetlabs.puppet</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>OnDemand</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <false/>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>ProgramArguments</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <array>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>/usr/bin/puppet</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>agent</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>--verbose</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>--no-daemonize</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>--logdest</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '                <string>console</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        </array>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>RunAtLoad</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <true/>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>ServiceDescription</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <string>Puppet Daemon</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>ServiceIPC</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <false/>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>StandardErrorPath</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <string>/var/log/puppet/puppet.err</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <key>StandardOutPath</key>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '        <string>/var/log/puppet/puppet.out</string>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '</dict>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo '</plist>' >> /Library/LaunchDaemons/com.puppetlabs.puppet.plist

echo "-- Set permissions on launchdaemon file..."
sudo chown root:wheel /Library/LaunchDaemons/com.puppetlabs.puppet.plist  
sudo chmod 644 /Library/LaunchDaemons/com.puppetlabs.puppet.plist
echo "Permissions are now set"

echo "-- Write puppet configuration file..."
echo "[main]" > /etc/puppet/puppet.conf
echo "server = puppet01.nacswildcats.org" >> /etc/puppet/puppet.conf
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

sed -i '' "s/tag = /tag = ${TAG}/g" /opt/fusioninventory-agent/agent.cfg

# Download create User script
#curl -k -O https://raw.githubusercontent.com/nastechnology/mac-bootstrap/master/createUser.sh

#chmod +x ./createUser.sh


echo "Don't forget to check the inventory tag to /opt/fusioninventory-agent/agent.cfg"
echo "Then reboot you device"
