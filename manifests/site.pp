# This document serves as an example of how to deploy
# basic multi-node openstack environments.
# In this scenario Quantum is using OVS with GRE Tunnels
# Swift is not included.

# Switch this to false after your first run to prevent unsafe operations
# from potentially running again
$initial_setup           = true


########### Proxy Configuration ##########
# If you use an HTTP/HTTPS proxy, point this at its URL.
#$proxy			= 'http://proxy-rtp-1.cisco.com:8080'
$proxy	= false
      

####### shared variables ##################
# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments
$build_node_fqdn	= 'build-node.ctoccllab.cisco.com'
$multi_host		= true
# By default, corosync uses multicasting. It is possible to disable
# this if your environment require it
#$corosync_unicast        = true
# assumes that eth0 is the public interface
$public_interface        = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface       = 'eth0.40'
# credentials
$admin_email             = 'root@localhost'
$admin_password          = 'Cisco123'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$glance_on_swift         = false
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
$fixed_network_range     = '10.4.0.0/24'
$floating_ip_range       = '192.168.150.200/32'
# switch this to true to have all service log at verbose
$verbose                 = false
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = false
#### end shared variables #################

# multi-node specific parameters
# The address services will attempt to connect to the controller with
$controller_node_address       = '192.168.150.11'
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

$controller_hostname           = 'control'
$controller_node_network       = '192.168.150.0'

$sql_connection = "mysql://nova:${nova_db_password}@${controller_node_address}/nova"

import 'cobbler-node'
import 'core'


