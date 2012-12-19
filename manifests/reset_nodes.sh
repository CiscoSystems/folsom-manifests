#!/bin/bash
# A simple script to rebuild nodes managed by cobbler and puppet.
# Execute the script by clean_node.sh <cobbler_system_name> <domain_name>.
# You can get the name from cobbler system list command.

echo "Resetting nodes!"
echo "This script will remove and reset the nodes in 15 seconds, ^C to cancel!"
sleep 15

#Changed cert clean to clean node so node is removed from stored configs db
echo "Removing nodes from cobbler"
for n in `cobbler system list` 
do cobbler system remove --name=$n
done
echo "Re-running puppet apply on /etc/puppet/manifests/site.pp"
puppet apply /etc/puppet/manifests/site.pp
echo "Re-building the nodes"
for n in `cobbler system list`
do /etc/puppet/manifests/clean_node.sh $n
done
