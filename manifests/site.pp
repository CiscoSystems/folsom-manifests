# This document serves as an example of how to deploy
# basic multi-node openstack environments.
# In this scenario Quantum is using OVS with GRE Tunnels
# Swift is not included.

# Switch this to false after your first run to prevent unsafe operations
# from potentially running again
$initial_setup           = true

########### Proxy Configuration ##########
# If you use an HTTP/HTTPS proxy, point this at its URL.
$proxy			= "http://proxy-rtp-1.cisco.com:8080"
#$proxy	= false
      
########### Build Node (Cobbler, Puppet Master, NTP) ######
$build_node_fqdn        = "build-node.ctocllab.cisco.com"

########### NTP Configuration ############
$company_ntp_server	= "ntp.esl.cisco.com"

########### Cobbler Variables ############
$cobbler_node_ip = '172.29.74.196'
$node_subnet = '172.29.74.0'
$node_netmask = '255.255.254.0'
$node_gateway = '172.29.74.1'
$dhcp_ip_low = '172.29.74.194'
$dhcp_ip_high = '172.29.74.205'
$domain_name = 'ctocllab.cisco.com'
$cobbler_proxy = "http://${cobbler_node_ip}:3142/"

####### Preseed File Configuration #######
# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
# The following variables may be changed by the system admin:
# 1) admin_user
# 2) password_crypted
# Default user is: localadmin
# An example MD5 crypted password is "ubuntu": $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
$admin_user = 'localadmin'
$password_crypted = '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1'

### Advanced Users Configuration ###
$node_dns = "${cobbler_node_ip}"
$ip = "${cobbler_node_ip}"
$dns_service = "dnsmasq"
$dhcp_service = "dnsmasq"


########### OpenStack Variables ############
# The address services will attempt to connect to the controller with
$controller_node_address       = '172.29.74.194'
$controller_node_network       = '172.29.74.0'
$db_allowed_network            = '172.29.74.%'
$controller_hostname           = 'p5-control01'
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

# Quantum does not support (Folsom) multi_host feature. This should be
# false to avoid running nova-network on compute nodes.
$multi_host		= false

# Assumes that eth0 is the API Interface
# This is also node as the Management Interface
$public_interface        = 'eth0'
# Interface used for vm networking connectivity when nova-network is being used.
# Quantum does not required this value, eth0 as default value will be fine. 
$private_interface	= 'eth0'
# This is use for external connectivity such as floating IPs (only in network/controller node)
$external_interface	 = 'eth1'

# OpenStack Services Credentials
$admin_email             = 'root@localhost'
$admin_password          = 'Cisco123'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_user		 = 'nova'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$glance_sql_connection   = "mysql://glance:${glance_db_password}@${controller_node_address}/glance"
$glance_host		 = "${controller_node_address}"
$glance_on_swift         = false
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
#$fixed_network_range     = '10.0.0.0/24'
$floating_ip_range       = '172.29.74.254/32'
# Nova DB connection
$sql_connection = "mysql://${nova_user}:${nova_db_password}@${controller_node_address}/nova"
$glance_sql_connection = "mysql://${nova_user}:${glance_db_password}@${controller_node_address}/glance"
# Switch this to true to have all service log at verbose
$verbose                 = false
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = false
#### end shared variables #################

####### Adding Core Configuration and Cobbler Nodes Definition #####
import 'cobbler-node'
import 'core'

node /build-node/ inherits master-node {
cobbler::node { "p5-control01":
 mac => "A4:4C:11:13:98:4F",
 ip => "172.29.74.194",
 ### UCS CIMC Details ###
 power_address => "172.29.74.170",
 power_user => "admin",
 power_password => "password",
 power_type => "ipmitool",
 ### Advanced Users Configuration ###
 profile => "precise-x86_64-auto",
 domain => $::domain_name,
 node_type => "control",
 preseed => "cisco-preseed",
 }


cobbler::node { "p5-compute01":
 mac => "A4:4C:11:13:56:74",
 ip => "172.29.74.197",
 ### UCS CIMC Details ###
 power_address => "172.29.74.173",
 power_user => "admin",
 power_password => "password",
 power_type => "ipmitool",
 ### Advanced Users Configuration ###
 profile => "precise-x86_64-auto",
 domain => $::domain_name,
 node_type => "compute",
 preseed => "cisco-preseed",
 }

### Repeat as needed ###
}
node p5-control01 inherits control { }
node p5-compute01 inherits compute { }
### Repeat as needed ###
