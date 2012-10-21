# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
# In this scenario Quantum is using OVS plugin and Swift
# is not being used. 

# Switch this to false after your first run to prevent unsafe operations
# from potentially running again
$initial_setup           = true

# deploy a script that can be used to test nova
class { 'openstack::test_file': }

########### Folsom Release ###############
# Load apt prerequisites.  This is only valid on Ubuntu systmes
exec { "apt-update" :
	command => "/usr/bin/apt-get update",
	refreshonly => true,
}

Apt::Source <| |> ~> Exec["apt-update"]

Exec["apt-update"] -> Package <| |>

apt::source { "cisco-openstack-mirror_folsom-proposed":
	location => "ftp://ftpeng.cisco.com/openstack/cisco/",
	release => "folsom-proposed",
	repos => "main",
	key => "E8CC67053ED3B199",
	key_server => "pgpkeys.mit.edu"
}

####### shared variables ##################
# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments
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
$verbose                 = 'false'
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = 'false'
#### end shared variables #################

# multi-node specific parameters
# The address services will attempt to connect to the controller with
$controller_node_address       = '192.168.150.11'
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

$controller_hostname           = 'control'
# The bind address for corosync. Should match the subnet the controller
# nodes use for the actual IP addresses
$controller_node_network       = '192.168.150.0'

$sql_connection = "mysql://nova:${nova_db_password}@${controller_node_address}/nova"

# /etc/hosts entries for the controller nodes
host { $controller_hostname:
  ip => $controller_node_internal
}
####
# Active and passive nodes are mostly configured identically.
# There are only two places where the configuration is different:
# whether openstack::controller is flagged as enabled, and whether
# $ha_primary is set to true on openstack_admin::controller::ha
####

# Load the cobbler node defintios needed for the preseed of nodes
import 'cobbler-node'

#Common configuration for all node compute, controller, storage but puppet-master/cobbler
node ntp {
 class { ntp:
    servers => [ "192.168.150.254" ],
    ensure => running,
    autoupdate => true,
  }
}

node /control/ {

class { 'collectd':
        graphitehost => 'build-node.cisco.openstack.com',
}

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    network_manager         => 'nova.network.quantum.manager.QuantumManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    glance_on_swift         => $glance_on_swift,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => false,

    ######### quantum variables #############
    quantum_url             	 => "http://${controller_node_address}:9696",
    quantum_admin_tenant_name    => 'services',
    quantum_admin_username       => 'quantum',
    quantum_admin_password       => 'quantum',
    quantum_admin_auth_url       => "http://${controller_node_address}:35357/v2.0",
    libvirt_vif_driver      	 => 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver',
    host         		 => 'controller',
    quantum_sql_connection       => "mysql://quantum:quantum@${controller_node_address}/quantum",
    quantum_auth_host            => "${controller_node_address}",
    quantum_auth_port            => "35357",
    quantum_rabbit_host          => "${controller_node_address}",
    quantum_rabbit_port          => "5672",
    quantum_rabbit_user          => "quantum",
    quantum_rabbit_password      => "quantum",
    quantum_rabbit_virtual_host  => "/quantum",
    quantum_control_exchange     => "quantum",
    quantum_core_plugin          => "quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2",
    ovs_bridge_uplinks      	 => ['br-ex:eth0.40'],
    ovs_bridge_mappings          => ['default:br-ex'],
    ovs_tenant_network_type  	 => "vlan",
    ovs_network_vlan_ranges  	 => "default:1000:2000",
    ovs_integration_bridge   	 => "br-int",
    ovs_enable_tunneling    	 => "False",
    ovs_tunnel_bridge        	 => "br-tun",
    ovs_tunnel_id_ranges     	 => "1:1000",
    ovs_local_ip             	 => "10.0.0.1",
    ovs_server               	 => false,
    ovs_root_helper          	 => "sudo quantum-rootwrap /etc/quantum/rootwrap.conf",
    ovs_sql_connection       	 => "mysql://quantum:quantum@${controller_node_address}/quantum",
    quantum_db_password      	 => "quantum",
    quantum_db_name        	 => 'quantum',
    quantum_db_user          	 => 'quantum',
    quantum_db_host          	 => $controller_node_address,
    quantum_db_allowed_hosts 	 => ['localhost','192.168.150.%'],
    quantum_db_charset       	 => 'latin1',
    quantum_db_cluster_id    	 => 'localzone',
    quantum_email              	 => "quantum@${controller_node_address}",
    quantum_public_address       => "${controller_node_address}",
    quantum_admin_address        => "${controller_node_address}",
    quantum_internal_address     => "${controller_node_address}",
    quantum_port                 => '9696',
    quantum_region               => 'RegionOne',
    l3_interface_driver          => "quantum.agent.linux.interface.OVSInterfaceDriver",
    l3_use_namespaces            => "False",
    l3_metadata_ip               => "169.254.169.254",
    l3_external_network_bridge   => "br-ex",
    l3_root_helper               => "sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf",
    #quantum dhcp
    dhcp_state_path         	 => "/var/lib/quantum",
    dhcp_interface_driver   	 => "quantum.agent.linux.interface.OVSInterfaceDriver",
    dhcp_driver        	 	 => "quantum.agent.linux.dhcp.Dnsmasq",
    dhcp_use_namespaces     	 => "False",
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

}


node /compute0/ inherits compute_base {

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

class { 'collectd':
        graphitehost => 'build-node.cisco.openstack.com',
}

  class { 'openstack::compute':
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    internal_address   => $ipaddress_eth0,
    libvirt_type       => 'kvm',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.quantum.manager.QuantumManager',
    multi_host         => $multi_host,
    sql_connection     => $sql_connection,
    nova_user_password => $nova_user_password,
    rabbit_host        => $controller_node_internal,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    glance_api_servers => "${controller_node_internal}:9292",
    vncproxy_host      => $controller_node_public,
    vnc_enabled        => 'true',
    verbose            => $verbose,
    manage_volumes     => true,
    nova_volume        => 'nova-volumes',
    # quantum config
    quantum_url             	 	=> "http://${controller_node_address}:9696",
    quantum_admin_tenant_name    	=> 'services',
    quantum_admin_username       	=> 'quantum',
    quantum_admin_password       	=> 'quantum',
    quantum_admin_auth_url       	=> "http://${controller_node_address}:35357/v2.0",
    libvirt_vif_driver      	 	=> 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver',
    libvirt_use_virtio_for_bridges      => 'True',
    host        	 		=> 'compute',
    #quantum general
    quantum_log_verbose          	=> "False",
    quantum_log_debug            	=> "False",
    quantum_bind_host            	=> "0.0.0.0",
    quantum_bind_port            	=> "9696",
    quantum_sql_connection       	=> "mysql://quantum:quantum@${controller_node_address}/quantum",
    quantum_auth_host            	=> "${controller_node_address}",
    quantum_auth_port            	=> "35357",
    quantum_rabbit_host          	=> "${controller_node_address}",
    quantum_rabbit_port          	=> "5672",
    quantum_rabbit_user          	=> "quantum",
    quantum_rabbit_password      	=> "quantum",
    quantum_rabbit_virtual_host  	=> "/quantum",
    quantum_control_exchange     	=> "quantum",
    quantum_core_plugin            	=> "quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2",
    quantum_mac_generation_retries 	=> 16,
    quantum_dhcp_lease_duration    	=> 120,
    #quantum ovs
    ovs_bridge_uplinks      		=> ['br-ex:eth0.40'],
    ovs_bridge_mappings      		=> ['default:br-ex'],
    ovs_tenant_network_type  		=> "vlan",
    ovs_network_vlan_ranges  		=> "default:1000:2000",
    ovs_integration_bridge   		=> "br-int",
    ovs_enable_tunneling    		=> "False",
    ovs_tunnel_bridge       	 	=> "br-tun",
    ovs_tunnel_id_ranges     		=> "1:1000",
    ovs_local_ip             		=> "10.0.0.1",
    ovs_server               		=> false,
    ovs_root_helper          		=> "sudo quantum-rootwrap /etc/quantum/rootwrap.conf",
    ovs_sql_connection       		=> "mysql://quantum:quantum@${controller_node_address}/quantum",
  }

}

node /build-node/ inherits "cobbler-node" {
 
#change the servers for your NTP environment
  class { ntp:
    servers => [ "ntp.esl.cisco.com"],
    ensure => running,
    autoupdate => true,
  }


class { 'nagios': }

class { 'collectd': 
	graphitehost => 'build-node.cisco.openstack.com',
}

class { 'graphite': 
	graphitehost => 'build-node.cisco.openstack.com',
}


# set up a local apt cache.  Eventually this may become a local mirror/repo instead
  class { apt-cacher-ng:
    }

# set the right local puppet environment up.  This builds puppetmaster with storedconfigs (a nd a local mysql instance)
  class { puppet:
    run_master 			=> true,
    puppetmaster_address 	=> 'build-node.cisco.openstack.com',
    certname 			=> 'build-node.cisco.openstack.com',
    mysql_password 		=> 'ubuntu',
  }<-
  file {'/etc/puppet/files':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
  }

  file {'/etc/puppet/fileserver.conf':
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => '
# This file consists of arbitrarily named sections/modules
# defining where files are served from and to whom

# Define a section "files"
# Adapt the allow/deny settings to your needs. Order
# for allow/deny does not matter, allow always takes precedence
# over deny
[files]
  path /etc/puppet/files
  allow *
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24

[plugins]
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24
',
  }

}
node default {
  notify{"Default Node: Perhaps add a node definition to site.pp": }
}
