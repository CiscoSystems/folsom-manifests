Folsom-manifests
================

Example manifests for the Folsom release of Openstack

This repo contains a branch for each configuration environment.
For instance the all-in-one branch contains the README and config
files needed for that kind of environment.

You should swich to the branch corresponding your environment set up:

	git checkout <config-name>
	i.e. git checkout all-in-one

Adding New Config Environments
==============================

Different configs are in different branches. 

	git branch <config-name>

	git push origin <config-name>

	git checkout <config-name>

edit your config files

	git add -A

	git commit -m 'add a commit message to describe your config files or changes'

	git push
