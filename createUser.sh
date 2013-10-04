#!/bin/sh
USERNAME=$1
. /etc/rc.common
dscl . create /Users/${USERNAME}
dscl . create /Users/${USERNAME}  RealName "Basic User"
dscl . create /Users/${USERNAME}  hint "Default"
dscl . create /Users/${USERNAME}  picture "/Library/User Pictures/Animals/Penguin.tif"
dscl . passwd /Users/${USERNAME}  school
dscl . create /Users/${USERNAME}  UniqueID 575
dscl . create /Users/${USERNAME}  PrimaryGroupID 20
dscl . create /Users/${USERNAME}  UserShell /bin/bash
dscl . create /Users/${USERNAME}  NFSHomeDirectory /Users/${USERNAME} 
cp -R /System/Library/User\ Template/English.lproj /Users/${USERNAME} 
chown -R ${USERNAME} :staff /Users/${USERNAME} 
