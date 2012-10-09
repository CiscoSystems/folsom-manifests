# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

# Switch this to false after your first run to prevent unsafe operations
# from potentially running again
$initial_setup           = true


# deploy a script that can be used to test nova
class { 'openstack::test_file': }


########### Folsom Release ###############
# Load apt prerequisites.  This is only valid on Ubuntu systmes
exec { "apt-update" :
	command => "/usr/bin/apt-get update"
}

Apt::Source <| |> -> Exec["apt-update"]

Exec["apt-update"] -> Package <| |>

apt::source { "cisco-openstack-mirror_folsom-proposed":
	location => "ftp://ftpeng.cisco.com/openstack/cisco/",
	release => "folsom-proposed",
	repos => "main",
	key => "E8CC67053ED3B199",
	key_server => "pgpkeys.mit.edu"
        #key_server => "hkp://pgpkeys.mit.edu:443"
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
$glance_on_swift         = 'false'
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
$fixed_network_range     = '10.4.0.0/24'
$floating_ip_range       = '192.168.160.0/24'
# switch this to true to have all service log at verbose
$verbose                 = 'false'
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = 'false'
# Swift addresses:
#$swift_proxy_address    = 'swiftproxy'
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

# include and load swift config and node definitions:
#import 'swift-nodes'

# Load the cobbler node defintios needed for the preseed of nodes
import 'cobbler-node'
# expot an authhorized keys file to the root user of all nodes.
# This is most useful for testing.
#import 'ssh-keys'
#import 'clean-disk'
#Common configuration for all node compute, controller, storage but puppet-master/cobbler
node ntp {
 class { ntp:
    servers => [ "192.168.150.254" ],
    ensure => running,
    autoupdate => true,
  }
}

node compute_base inherits ntp {
}

node glance_import inherits ntp {

}
node glance_import_2 inherits ntp {

$release = 'precise'
$image_name = "${release}.img"
$image_uri = "http://build-node/${image_name}"
$os_tenant = 'openstack'
$os_username = 'admin'
$os_password = 'Cisco123'
$os_auth_url = "http://192.168.150.11:5000/v2.0/"

exec {"glance add -T ${os_tenant} -N ${os_auth_url} -K ${os_password} -I ${os_username} name=${release}-puppet is_public=true disk_format='qcow2' container_format='bare' copy_from=${image_uri}":
  path => ['/bin','/usr/bin'],
  cwd => '/var/www',
  unless => "glance -T ${os_tenant} -N ${os_auth_url} -K ${os_password} -I ${os_username} index | grep ${precise}-puppet 2>/dev/null",
#  require => Class["openstack::controller"]
  }
}

node /control/ inherits glance_import {

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
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
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

# configure the keystone service user and endpoint
  #class { 'swift::keystone::auth':
  #  auth_name => $swift_user,
  #  password => $swift_user_password,
  #  address  => $swift_proxy_address,
  #}

}


node /compute0/ inherits compute_base {

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }



  class { 'openstack::compute':
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    internal_address   => $ipaddress_eth0,
    libvirt_type       => 'kvm',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
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
  }

}

node /build-node/ inherits "cobbler-node" {
 
#change the servers for your NTP environment
  class { ntp:
    servers => [ "ntp.esl.cisco.com"],
    ensure => running,
    autoupdate => true,
  }


# set up a local apt cache.  Eventually this may become a local mirror/repo instead
  class { apt-cacher-ng:
    }

# set the right local puppet environment up.  This builds puppetmaster with storedconfigs (a nd a local mysql instance)
  class { puppet:
    run_master => true,
    puppetmaster_address => $::fqdn,
    certname => 'build-node.cisco.openstack.com',
    mysql_password => 'ubuntu',
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
