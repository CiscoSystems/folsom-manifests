#!/bin/bash
# A simple script to rebuild nodes managed by cobbler and puppet.
# Execute the script by clean_node.sh <cobbler_system_name> <domain_name>.
# You can get the name from cobbler system list command.

if [ -n "$2" ]
then
  domain="$2"
else
  domain=`hostname -d`
fi

echo "PXE booting $1"
sudo cobbler system edit --name="$1" --netboot-enable=Y
sudo cobbler system poweroff --name="$1" >/dev/null
sleep 5
sudo cobbler system poweron --name="$1" >/dev/null

#Changed cert clean to clean node so node is removed from stored configs db
echo "Cleaning up puppet and ssh records for $1"
sudo puppet node clean "$1"."$domain" >/dev/null
sudo ssh-keygen -R "$1" >/dev/null 2>&1
sudo ssh-keygen -R `host "$1" | awk '{print \$4}'` > /dev/null 2>&1
