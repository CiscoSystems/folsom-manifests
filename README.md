Folsom-manifests
================

Install Ubuntu 12.04.1 LTS x86_64 (preferred)

  apt-get update && apt-get upgrade && apt-get install git puppet ipmitool python-jinja2 python-passlib python-yaml

clone this repo to your build node

  git clone https://github.com/CiscoSystems/folsom-manifests -b multi-node-yaml
  cp folsom-manifests/* /etc/puppet/manifests

Clone the puppet modules

  cd /etc/puppet/manifests/
  /etc/puppet/manifests/puppet-modules.sh

Edit the yaml config:

  cp /etc/puppet/manifests/site.yaml{.example,}
  vi /etc/puppet/manifests/site.yaml

Run the site generator:

  /etc/puppet/manifests/create_site.py

"Reset" your environment

  puppet apply -v /etc/puppet/manifests/site.pp
  puppet plugin download
  /etc/puppet/manifests/reset_site.sh

Wait ~ 15 minutes, and then check out your new OpenStack cluster:

  http://{control_node_ip_or_dns}/


