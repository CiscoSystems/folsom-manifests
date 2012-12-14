#!/bin/sh
# This script will get all puppet modules required
# for the deployment of the Cisco OpenStack Edition (COE)
echo "Getting Puppet Modules"
FILE_LIST=modules.list
RELEASE=folsom
REPO=https://github.com/CiscoSystems/
PUPPET_PATH=/etc/puppet/

while IFS= read -r module
do
        # display $line or do somthing with $line
	# echo "$module"
	git clone -b $RELEASE "$REPO"puppet-"$module".git "$PUPPET_PATH"modules/$module
done <"$FILE_LIST"

# TODO: This module does not follow the naming "puppet-module" convention
git clone -b $RELEASE "$REPO"puppetlabs-lvm.git "$PUPPET_PATH"modules/lvm
