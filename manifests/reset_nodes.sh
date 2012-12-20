#!/bin/bash
# A simple script to reset and rebuild all the nodes managed by cobbler and puppet.
# 

echo "Resetting nodes!"
echo "This script will remove and reset the nodes in 15 seconds, ^C to cancel!"
echo "This is a destructive process!!!"
sleep 15

echo "Removing nodes from cobbler"
sudo sh -c 'for n in `cobbler system list` ; do cobbler system remove --name=$n ; done'

echo "Re-running puppet apply on /etc/puppet/manifests/site.pp"
sudo puppet apply /etc/puppet/manifests/site.pp

echo "Re-building the nodes"
sudo sh -c 'for n in `cobbler system list` ; do /etc/puppet/manifests/clean_node.sh $n ; done'
