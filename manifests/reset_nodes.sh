#!/bin/bash
# A simple script to reset and rebuild all the nodes managed by cobbler and puppet.
# 
# This script is intended to help you rebuild your _ENTIRE_ system from scratch
# Not the cleanest way in the world to do this
# Please be careful, as all of the nodes defined in cobbler will be removed, recreated
# and rebooted.

echo "Resetting nodes!"
echo " !!!!!!!!!!!!!!!!! "
echo "NOTE: You probably should only use this if you're rebuilding everything!"
echo " !!!!!!!!!!!!!!!!! "
echo "This script will remove and reset the nodes in 15 seconds, ^C to cancel!"
echo "This is a destructive process!!!"
sleep 15

echo "Removing nodes from cobbler"
sudo sh -c 'for n in `cobbler system list` ; do cobbler system remove --name=$n ; done'

echo "Re-running puppet apply on /etc/puppet/manifests/site.pp"
sudo puppet apply /etc/puppet/manifests/site.pp

echo "Re-building the nodes"
sudo sh -c 'for n in `cobbler system list` ; do /etc/puppet/manifests/clean_node.sh $n ; done'
