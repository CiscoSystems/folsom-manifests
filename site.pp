# This document serves as an example of how to deploy
# basic multi-node openstack environments.
# In this scenario Quantum is using OVS with GRE Tunnels
# Swift is not included.

########### Proxy Configuration ##########
# If you use an HTTP/HTTPS proxy, uncomment this setting and specify the correct proxy URL.
# If you do not use an HTTP/HTTPS proxy, leave this setting commented out.
#$proxy			= "http://proxy-server:port-number"
      
########### Build Node (Cobbler, Puppet Master, NTP) ######
$build_node_fqdn        = "build-os.dmz-pod2.lab"

########### NTP Configuration ############
$company_ntp_server	= "192.168.220.1"

########### Cobbler Variables ############
$cobbler_node_ip 	= '192.168.220.254'
$node_subnet 		= '192.168.220.0'
$node_netmask 		= '255.255.255.0'
$node_gateway 		= '192.168.220.1'
$dhcp_ip_low 		= '192.168.220.240'
$dhcp_ip_high 		= '192.168.220.250'
$domain_name 		= 'dmz-pod2.lab'
$cobbler_proxy 		= "http://${cobbler_node_ip}:3142/"

####### Preseed File Configuration #######
# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
# The following variables may be changed by the system admin:
# 1) admin_user
# 2) password_crypted
# Default user is: localadmin
# An example MD5 crypted password is "ubuntu": $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
$admin_user 		= 'localadmin'
$password_crypted 	= '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1'

### Advanced Users Configuration ###
$node_dns 	= "${cobbler_node_ip}"
$ip 		= "${cobbler_node_ip}"
$dns_service 	= "dnsmasq"
$dhcp_service 	= "dnsmasq"


########### OpenStack Variables ############
# The address services will attempt to connect to the controller with
$controller_node_address       = '192.168.220.43'
$controller_node_network       = '192.168.220.0'
$db_allowed_network            = '192.168.220..%'
$controller_hostname           = 'control03'
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

# Quantum does not support (Folsom) multi_host feature. This should be
# false to avoid running nova-network on compute nodes.
$multi_host			= false

# Assumes that eth0 is the API Interface
# This is also node as the Management Interface
$public_interface        	= 'eth0'
# Interface used for vm networking connectivity when nova-network is being used.
# Quantum does not required this value, eth0 as default value will be fine. 
$private_interface		= 'eth0'
# This is use for external connectivity such as floating IPs (only in network/controller node)
$external_interface	 	= 'eth0.221'

# Select the drive on which OpenStack will be installed. Current assumption is that
# all machines will have the same device name targeted
$install_drive           = '/dev/sdc'

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
$glance_on_swift         = false
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
#$floating_ip_range       = '172.29.74.254/32'
# Nova DB connection
$sql_connection 	 = "mysql://${nova_user}:${nova_db_password}@${controller_node_address}/nova"
# Switch this to true to have all service log at verbose
$verbose                 = false
# by default it does not enable atomatically adding floating IPs
#$auto_assign_floating_ip = false
#### end shared variables #################

####### Adding Core Configuration and Cobbler Nodes Definition #####
import 'cobbler-node'
import 'core'

node /build-os/ inherits master-node {
cobbler::node { "control03":
 mac 		=> "A4:4C:11:13:5E:5C",
 ip 		=> "192.168.220.43",
 ### UCS CIMC Details ###
 power_address 	=> "192.168.220.13",
 power_user 	=> "admin",
 power_password => "password",
 power_type 	=> "ipmitool",
 ### Advanced Users Configuration ###
 profile 	=> "precise-x86_64-auto",
 domain 	=> $::domain_name,
 node_type 	=> "control",
 preseed 	=> "controller-preseed",
 }


cobbler::node { "compute01":
 mac 		=> "A4:4C:11:13:52:80",
 ip 		=> "192.168.220.51",
 ### UCS CIMC Details ###
 power_address 	=> "192.168.220.4",
 power_user 	=> "admin",
 power_password => "password",
 power_type 	=> "ipmitool",
 ### Advanced Users Configuration ###
 profile 	=> "precise-x86_64-auto",
 domain 	=> $::domain_name,
 node_type 	=> "compute",
 preseed 	=> "cisco-preseed",
 }

### Repeat as needed ###
}
node control03 inherits control { }
node compute01 inherits compute { }
### Repeat as needed ###
