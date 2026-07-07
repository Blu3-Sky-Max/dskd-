#!/bin/bash
#==================================================================================
# Author: Usman Opeyemi Olanrewaju (Blu3-Sky) 
# Created: 2026/07/07 
# 
#
# Purpose: one-click installer for dskd.
#           Moves all required files to the correct system paths,
#           sets permissions, and starts the daemon via systemd.
# 
# Run: sudo ./dsk-install.sh 
# ================================================================================
 
# Allow only root

 if [ $EUID != 0 ] ; then 
 echo -e "\033[31m$0Installer needs the root \033[0m" 
  exit 19 
fi 




File="dsk-daemon.sh" 
Service="dsk-daemon.service" 
Conf="dsk-daemon.conf" 

echo -e "\033[31mChecking required files...\033[0m"

# loop countdown
i=5 ; until [ $i -eq 0  ] ; do
   echo  $i  
  sleep 2
   i=$(( i - 1 ))
done

# Missing file check 

missing=0
for i in "$File" "$Conf" "$Service"; do
    if [ ! -f "$i" ]; then
        echo -e "\033[31mMissing file: $i \033[0m"
        missing=1
    fi
done


if [ "$missing" -eq 1 ]; then
    echo -e "\033[31m[ERROR] One or more required files are missing. Aborting.\033[0m"
    echo  "Make sure $File, $Conf, and $Service are in the same directory as this installer file."

    exit 20


fi
 echo "--> --> All Required Files Found  <-- <-- " 

cp $File    "/usr/local/bin/." 
cp $Conf    "/usr/local/bin/." 
cp $Service "/etc/systemd/system/."


echo -e  "\033[36m[OK] WE ARE SET \033[0m" 

sudo systemctl enable --now dsk-daemon 
sudo systemctl start dsk-daemon 
sudo systemctl status dsk-daemon 
