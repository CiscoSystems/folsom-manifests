# This document serves as an example of how to deploy
# basic multi-node openstack environments.
# In this scenario Quantum is using OVS with GRE Tunnels
# Swift is not included.

########### Proxy Configuration ##########
# If you use an HTTP/HTTPS proxy, uncomment this setting and specify the correct proxy URL.
# If you do not use an HTTP/HTTPS proxy, leave this setting commented out.
#{% if config.proxy %}
$proxy			= "{{ config.proxy }}"
#{% endif %}

# If you are behind a proxy you may choose not to use our ftp distribution, and
# instead try our http distribution location. Note the http location is not
# a permanent location and may change at any time.
$location 		= "ftp://ftpeng.cisco.com/openstack/cisco"
# Alternate, uncomment this one, and coment out the one above
#$location		= "http://128.107.252.163/openstack/cisco"
########### Build Node (Cobbler, Puppet Master, NTP) ######
# Change the following to the host name you have given your build node
$build_node_name        = "{{ job.build_node.name }}"

########### NTP Configuration ############
# Change this to the location of a time server in your organization accessible to the build server
# The build server will synchronize with this time server, and will in turn function as the time
# server for your OpenStack nodes
$company_ntp_server	= "{{ config.ntp_server }}"

########### Build Node Cobbler Variables ############
# Change these 5 parameters to define the IP address and other network settings of your build node
# The cobbler node *must* have this IP configured and it *must* be on the same network as
# the hosts to install
$cobbler_node_ip 	= '{{ job.build_node.ip }}'
$node_subnet 		= '{{ config.subnet }}'
$node_netmask 		= '{{ config.netmask }}'
# This gateway is optional - if there's a gateway providing a default route, put it here
# If not, comment it out
$node_gateway 		= '{{ config.gateway }}'
# This domain name will be the name your build and compute nodes use for the local DNS
# It doesn't have to be the name of your corporate DNS - a local DNS server on the build
# node will serve addresses in this domain - but if it is, you can also add entries for
# the nodes in your corporate DNS iand they will be usable *if* the above addresses 
# are routeable from elsewhere in your network.
$domain_name 		= '{{ config.domain }}'
# This setting likely does not need to be changed
# To speed installation of your OpenStack nodes, it configures your build node to function
# as a caching proxy storing the Ubuntu install files used to deploy the OpenStack nodes
$cobbler_proxy 		= "http://${cobbler_node_ip}:3142/"

####### Preseed File Configuration #######
# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
# The preseed file automates the installation of Ubuntu onto the OpenStack nodes
#
# The following variables may be changed by the system admin:
# 1) admin_user
# 2) password_crypted
# 3) autostart_puppet -- whether the puppet agent will auto start
# Default user is: localadmin 
# Default MD5 crypted password is "ubuntu": $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
$admin_user 		= '{{ config.admin_user }}'
$password_crypted 	= '{{ config.admin_password_crypted }}'
$autostart_puppet       = true

########### OpenStack Variables ############
# These values define parameters which will be used to deploy and configure OpenStack
# once Ubuntu is installed on your nodes
#
# Change these next 3 parameters to the network settings of the node which will be your
# OpenStack control node
$controller_node_address       = '{{ job.control_node.ip }}'
$controller_node_network       = '{{ config.subnet }}'
$controller_hostname           = '{{ job.control_node.name }}'
# Specify the network which should have access to the MySQL database on the OpenStack control
# node. Typically, this will be the same network as defined in the controller_node_network
# parameter above. Use MySQL network wild card syntax to specify the desired network.
$db_allowed_network            = '{{ config.subnet_as_sql }}'
# These next two values typically do not need to be changed. They define the network connectivity
# of the OpenStack controller
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

# These next three parameters specify the networking hardware used in each node
# Current assumption is that all nodes have the same network interfaces and are
# cabled identically
#
# Specify which interface in each node is the API Interface
# This is also known as the Management Interface
$public_interface        	= 'eth0'
# Define the interface used for vm networking connectivity when nova-network is being used.
# Quantum does not required this value, so using eth0 will typically be fine. 
$private_interface		= 'eth0'
# Specify the interface used for external connectivity such as floating IPs (only in network/controller node)
$external_interface	 	= 'eth1'

# Select the drive on which Ubuntu and OpenStack will be installed in each node. Current assumption is
# that all nodes will be installed on the same device name
$install_drive           = '/dev/sdc'

########### OpenStack Service Credentials ############
# This block of parameters is used to change the user names and passwords used by the services which
# make up OpenStack. The following defaults should be changed for any production deployment
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
# Nova DB connection
$sql_connection 	 = "mysql://${nova_user}:${nova_db_password}@${controller_node_address}/nova"


# This value can be set to true to increase debug logging when trouble-shooting services
# It should not generally be set to true as it can impact service operation
$verbose                 = false

#### end shared variables #################


####### OpenStack Node Definitions #####
# This section is used to define the hardware parameters of the nodes which will be used
# for OpenStack. Cobbler will automate the installation of Ubuntu onto these nodes using
# these settings

# This describes the hardware of the nodes to the extent required to network-install their
# OS.
# Change this to suit your hardware; the supplied configuration works for UCSes with CIMC
# using a default password.
# If you have multiple different hardware types or disk configurations you may need to use
# multiple block types here.
define cobbler_node($node_type, $mac, $ip, $power_address, $power_user, $power_password, $power_type, $power_id) {
  cobbler::node { $name:
    mac 	   => $mac,
    ip 		   => $ip,
    ### UCS CIMC Details ###
    # Change these parameters to match the management console settings for your server
    power_address  => $power_address,
    power_user 	 => $power_user,
    power_password => $power_password,
    power_type     => $power_type,
    power_id       => $power_id,
    ### Advanced Users Configuration ###
    # These parameters typically should not be changed
    profile 	   => "precise-x86_64-auto",
    domain         => $::domain_name,
    node_type 	   => $node_type,
    preseed 	   => "cisco-preseed",
    log_host       => "{{ job.logging.host }}",
    log_port       => "{{ job.logging.port }}",
  }
}

node /build-node/ inherits master-node {

# This block defines the control server. Replace "control_server" with the host name of your
# OpenStack controller, and change the mac to the MAC address of the boot interface of your
# OpenStack controller. Change the ip to the IP address of your OpenStack controller

  cobbler_node { "{{ job.control_node.name }}": node_type => "control", mac => "{{ job.control_node.mac }}", ip => "{{ job.control_node.ip }}", power_address => "{{ job.control_node.power_address }}", power_user => "{{ job.control_node.power_user }}", power_password => "{{ job.control_node.power_password }}", power_type => "{{ job.control_node.power_type }}", power_id => "{{ job.control_node.power_id }}" }

# This block defines the first compute server. Replace "compute_server01" with the host name
# of your first OpenStack compute node, and change the mac to the MAC address of the boot
# interface of your first OpenStack compute node. Change the ip to the IP address of your first
# OpenStack compute node

# Begin compute node
#{% for node in job.compute_nodes %}
  cobbler_node { "{{ node.name }}": node_type => "compute", mac => "{{ node.mac }}", ip => "{{ node.ip }}", power_address  => "{{ node.power_address }}", power_user => "{{ node.power_user }}", power_password => "{{ node.power_password }}", power_type => "{{ node.power_type }}", power_id => "{{ node.power_id }}" }
#{% endfor %}
# End compute node

### Repeat as needed ###
# Make a copy of your compute node block above for each additional OpenStack node in your cluster
# and paste the copy in this section. Be sure to change the host name, mac, ip, and power settings
# for each node 


### End repeated nodes ###
}

### Node types ###
# These lines specify the host names in your OpenStack cluster and what the function of each host is

# Change build_server to the host name of your build node
node /{{ job.build_node.fqdn }}/ inherits build-node { }

# Change control_server to the host name of your control node
node /{{ job.control_node.fqdn }}/ inherits os_base { class { control: crosstalk_ip => '{{ job.control_node.ip }}'} }

# Change compute_server01 to the host name of your first compute node
#{% for node in job.compute_nodes %}
node /{{ node.fqdn }}/ inherits os_base { class { compute: internal_ip => '{{ node.ip }}', crosstalk_ip => '{{ node.ip }}'} }
#{% endfor %}

### Repeat as needed ###
# Copy the compute_server01 line above and paste a copy here for each additional OpenStack node in
# your cluster. Be sure to replace the compute_server01 parameter with the correct host name for
# each additional node


### End repeated nodes ###

########################################################################
### All parameters below this point likely do not need to be changed ###
########################################################################

### Advanced Users Configuration ###
# These four settings typically do not need to be changed
# In the default deployment, the build node functions as the DNS and static DHCP server for
# the OpenStack nodes. These settings can be used if alternate configurations are needed
$node_dns       = "${cobbler_node_ip}"
$ip 		= "${cobbler_node_ip}"
$dns_service 	= "dnsmasq"
$dhcp_service 	= "dnsmasq"

### Puppet Parameters ###
# These settings load other puppet components. They should not be changed
import 'cobbler-node'
import 'core'

## Define the default node, to capture any un-defined nodes that register
## Simplifies debug when necessary.

node default {
  notify{"Default Node: Perhaps add a node definition to site.pp": }
}
