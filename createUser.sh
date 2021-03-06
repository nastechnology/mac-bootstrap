#!/bin/sh
USERNAME=$1
ADMIN=$2
AUTO=$3

. /etc/rc.common
dscl . create /Users/${USERNAME}
dscl . create /Users/${USERNAME}  RealName "${USERNAME}"
dscl . create /Users/${USERNAME}  hint "Default"
dscl . create /Users/${USERNAME}  picture "/Library/User Pictures/Animals/Penguin.tif"
dscl . passwd /Users/${USERNAME}  school
dscl . create /Users/${USERNAME}  UniqueID 575
if $ADMIN ; then
dscl . create /Users/${USERNAME}  PrimaryGroupID 80
else
dscl . create /Users/${USERNAME}  PrimaryGroupID 20
fi
dscl . create /Users/${USERNAME}  UserShell /bin/bash
dscl . create /Users/${USERNAME}  NFSHomeDirectory /Users/${USERNAME} 
cp -R /System/Library/User\ Template/English.lproj /Users/${USERNAME} 
chown -R ${USERNAME}:staff /Users/${USERNAME} 

if $AUTO ; then
  defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser ${USERNAME}
  defaults write /Library/Preferences/com.apple.loginwindow autoLoginUID 575
fi
