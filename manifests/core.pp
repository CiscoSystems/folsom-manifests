# This document serves as an example of how to deploy
# basic multi-node openstack environments.
# In this scenario Quantum is using OVS with GRE Tunnels
# Swift is not included.


node base {
    $build_node_fqdn = "${::build_node_name}.${::domain_name}"

    ########### Folsom Release ###############

    # Disable pipelining to avoid unfortunate interactions between apt and
    # upstream network gear that does not properly handle http pipelining
    # See https://bugs.launchpad.net/ubuntu/+source/apt/+bug/996151 for details

    file { '/etc/apt/apt.conf.d/00no_pipelining':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'Acquire::http::Pipeline-Depth "0";'
    }

    # Load apt prerequisites.  This is only valid on Ubuntu systmes

#{% for archive in job.description.archives %}

    openstack::apt { "{{ archive.name }}":
      location => "{{ archive.location }}",
	  release => "{{ archive.pocket }}",
	  repos => "{{ archive.components|join:' ' }}",
   	  key => "{{ archive.key_id }}",
      key_content => '{{ archive.key_data }}',
    }

#{% endfor %}

    apt::pin { "cisco":
	priority => '990',
	originator => 'Cisco'
    }

    class { pip: }

    # Ensure that the pip packages are fetched appropriately when we're using an
    # install where there's no direct connection to the net from the openstack
    # nodes
    if ! $::default_gateway {
        Package <| provider=='pip' |> {
            install_options => "--index-url=http://${build_node_name}/packages/simple/",
        }
    } else {
        if($::proxy) {
            Package <| provider=='pip' |> {
                # TODO(ijw): untested
                install_options => "--proxy=$::proxy"
            }
        }
    }
    # (the equivalent work for apt is done by the cobbler boot, which sets this up as
    # a part of the installation.)

    class { 'collectd':
        graphitehost		=> $build_node_fqdn,
	management_interface	=> $::public_interface,
    }
}

node os_base inherits base {
    $build_node_fqdn = "${::build_node_name}.${::domain_name}"

    class { ntp:
	servers		=> [$build_node_fqdn],
	ensure 		=> running,
	autoupdate 	=> true,
    }

    # Deploy a script that can be used to test nova
    class { 'openstack::test_file': }

    class { 'openstack::auth_file':
	admin_password       => $admin_password,
	keystone_admin_token => $keystone_admin_token,
	controller_node      => $controller_node_internal,
    }

    class { "naginator::base_target":
    }

    # This value can be set to true to increase debug logging when
    # trouble-shooting services. It should not generally be set to
    # true as it is known to break some OpenStack components
    $verbose            = false

}

# A class because its simple implementation can only renumber one interface pair on startup
class numbered_vs_port($pair) {
    # If an interface with an address is put into a switch, you need to add a fix for bootup
    # and also do a similar fix during the initial add.

    $mapping = split($pair, ":")
    $bridge = $mapping[0]
    $port = $mapping[1]

    # Add the port to the bridge, as normal...
    # NB: copied from quantum::plugin::ovs::port
    vs_port {$port:
        ensure => present,
        bridge => $bridge,
        require => Vs_bridge[$bridge],
        notify => Service['openvswitch-fix-interface'] # but ensure that the IP address remains reachable
    }

    file { "/etc/init.d/openvswitch-fix-interface":
        owner => 'root',
        group => 'root',
        mode => '755',
        content => template('openvswitch-fix-interface.erb'),
    }
    # TODO: is this service guaranteed not to start until the vs_port is created?
    service { 'openvswitch-fix-interface':
        ensure => 'running',
        enable => true,
        require => Vs_port[$port],
    }
}

class control(
  $crosstalk_ip,
  $public_address          = $::controller_node_public,
  $public_interface        = $::public_interface,
  $private_interface       = $::private_interface,
  $internal_address        = $::controller_node_internal,
  $floating_range          = $::floating_ip_range,
  $fixed_range             = $::fixed_network_range,
  # by default it does not enable multi-host mode
  $multi_host              = $::multi_host,
  $network_manager         = 'nova.network.quantum.manager.QuantumManager',
  $verbose                 = $::verbose,
  $auto_assign_floating_ip = $::auto_assign_floating_ip,
  $mysql_root_password     = $::mysql_root_password,
  $admin_email             = $::admin_email,
  $admin_password          = $::admin_password,
  $keystone_db_password    = $::keystone_db_password,
  $keystone_admin_token    = $::keystone_admin_token,
  $glance_db_password      = $::glance_db_password,
  $glance_user_password    = $::glance_user_password,
  $glance_sql_connection   = $::glance_sql_connection,
  $glance_on_swift         = $::glance_on_swift,
  $nova_db_password        = $::nova_db_password,
  $nova_user_password      = $::nova_user_password,
  $rabbit_password         = $::rabbit_password,
  $rabbit_user             = $::rabbit_user,
  $export_resources        = false,
  ######### quantum variables #############
  $quantum_enabled			= true,
  $quantum_url             	= "http://${::controller_node_address}:9696",
  $quantum_admin_tenant_name    	= 'services',
  $quantum_admin_username       	= 'quantum',
  $quantum_admin_password       	= 'quantum',
  $quantum_admin_auth_url       	= "http://${::controller_node_address}:35357/v2.0",
  $quantum_ip_overlap              = false,
  $libvirt_vif_driver      	= 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver',
  $host         		 	= 'controller',
  $quantum_sql_connection       	= "mysql://quantum:quantum@${::controller_node_address}/quantum",
  $quantum_auth_host            	= "${::controller_node_address}",
  $quantum_auth_port            	= "35357",
  $quantum_rabbit_host          	= "${::controller_node_address}",
  $quantum_rabbit_port          	= "5672",
  $quantum_rabbit_user          	= "${::rabbit_user}",
  $quantum_rabbit_password      	= "${::rabbit_password}",
  $quantum_rabbit_virtual_host  	= "/",
  $quantum_control_exchange     	= "quantum",
  $quantum_core_plugin          	= "quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2",
  $ovs_bridge_uplinks      	= ["br-ex:${::external_interface}"],
  $ovs_bridge_mappings          	= ['default:br-ex'],
  $ovs_tenant_network_type  	= "gre",
  $ovs_network_vlan_ranges  	= "default:1000:2000",
  $ovs_integration_bridge   	= "br-int",
  $ovs_enable_tunneling    	= "True",
  $ovs_tunnel_bridge         	= "br-tun",
  $ovs_tunnel_id_ranges     	= "1:1000",
  $ovs_local_ip             	= $crosstalk_ip,
  $ovs_server               	= false,
  $ovs_root_helper          	= "sudo quantum-rootwrap /etc/quantum/rootwrap.conf",
  $ovs_sql_connection       	= "mysql://quantum:quantum@${::controller_node_address}/quantum",
  $quantum_db_password      	= "quantum",
  $quantum_db_name        	 	= 'quantum',
  $quantum_db_user          	= 'quantum',
  $quantum_db_host          	= $::controller_node_address,
  $quantum_db_allowed_hosts 	= ['localhost', "${::db_allowed_network}"],
  $quantum_db_charset       	= 'latin1',
  $quantum_db_cluster_id    	= 'localzone',
  $quantum_email              	= "quantum@${::controller_node_address}",
  $quantum_public_address       	= "${::controller_node_address}",
  $quantum_admin_address        	= "${::controller_node_address}",
  $quantum_internal_address     	= "${::controller_node_address}",
  $quantum_port                 	= '9696',
  $quantum_region               	= 'RegionOne',
  $l3_interface_driver          	= "quantum.agent.linux.interface.OVSInterfaceDriver",
  $l3_use_namespaces            	= "True",
  $l3_metadata_ip               	= "${::controller_node_address}",
  $l3_external_network_bridge   	= "br-ex",
  $l3_root_helper               	= "sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf",
  #quantum dhcp
  $dhcp_state_path         	= "/var/lib/quantum",
  $dhcp_interface_driver   	= "quantum.agent.linux.interface.OVSInterfaceDriver",
  $dhcp_driver        	 	= "quantum.agent.linux.dhcp.Dnsmasq",
  $dhcp_use_namespaces     	= "True",
  ) 

  {
    # Optionally assign an interface address to an OVS port
    if ($::numbered_vs_port == 'true') {
        class { numbered_vs_port: pair => 'br-int:$::public_interface'}
    }  elsif ($::numbered_vs_port != '') {
        class { numbered_vs_port: pair => '$::numbered_vs_port'}
    }

    class { 'openstack::controller':
        public_address              => $public_address,
    	public_interface            => $public_interface,
	    private_interface           => $private_interface,
    	internal_address            => $internal_address,
    	floating_range              => $floating_range,
    	fixed_range                 => $fixed_range,
    	multi_host                  => $multi_host,
    	network_manager             => $network_manager,
    	verbose                     => $verbose,
    	auto_assign_floating_ip     => $auto_assign_floating_ip,
    	mysql_root_password         => $mysql_root_password,
    	admin_email                 => $admin_email,
    	admin_password              => $admin_password,
    	keystone_db_password        => $keystone_db_password,
    	keystone_admin_token        => $keystone_admin_token,
    	glance_db_password          => $glance_db_password,
    	glance_user_password        => $glance_user_password,
        glance_sql_connection    => $glance_sql_connection,
        glance_on_swift          => $glance_on_swift,
    	nova_db_password            => $nova_db_password,
    	nova_user_password          => $nova_user_password,
    	rabbit_password             => $rabbit_password,
    	rabbit_user                 => $rabbit_user,
    	export_resources            => $export_resources,
    	quantum_enabled             => $quantum_enabled,
    	quantum_url                 => $quantum_url,
    	quantum_admin_tenant_name   => $quantum_admin_tenant_name,
    	quantum_admin_username      => $quantum_admin_username,
    	quantum_admin_password      => $quantum_admin_password,
    	quantum_admin_auth_url      => $quantum_admin_auth_url,
    	quantum_ip_overlap          => $quantum_ip_overlap,
    	libvirt_vif_driver          => $libvirt_vif_driver,
    	host                        => $host,
	    quantum_sql_connection      => $quantum_sql_connection,
    	quantum_auth_host           => $quantum_auth_host,
    	quantum_auth_port           => $quantum_auth_port,
    	quantum_rabbit_host         => $quantum_rabbit_host,
    	quantum_rabbit_port         => $quantum_rabbit_port,
    	quantum_rabbit_user         => $quantum_rabbit_user,
    	quantum_rabbit_password     => $quantum_rabbit_password,
    	quantum_rabbit_virtual_host => $quantum_rabbit_virtual_host,
    	quantum_control_exchange    => $quantum_control_exchange,
    	quantum_core_plugin         => $quantum_core_plugin,
    	ovs_bridge_uplinks          => $ovs_bridge_uplinks,
    	ovs_bridge_mappings         => $ovs_bridge_mappings,
    	ovs_tenant_network_type     => $ovs_tenant_network_type,
    	ovs_network_vlan_ranges     => $ovs_network_vlan_ranges,
    	ovs_integration_bridge      => $ovs_integration_bridge,
    	ovs_enable_tunneling        => $ovs_enable_tunneling,
    	ovs_tunnel_bridge           => $ovs_tunnel_bridge,
    	ovs_tunnel_id_ranges        => $ovs_tunnel_id_ranges,
    	ovs_local_ip                => $ovs_local_ip,
    	ovs_server                  => $ovs_server,
    	ovs_root_helper             => $ovs_root_helper,
    	ovs_sql_connection          => $ovs_sql_connection,
    	quantum_db_password         => $quantum_db_password,
    	quantum_db_name             => $quantum_db_name,
    	quantum_db_user             => $quantum_db_user,
    	quantum_db_host             => $quantum_db_host,
    	quantum_db_allowed_hosts    => $quantum_db_allowed_hosts,
    	quantum_db_charset          => $quantum_db_charset,
    	quantum_db_cluster_id       => $quantum_db_cluster_id,
    	quantum_email               => $quantum_email,
    	quantum_public_address      => $quantum_public_address,
    	quantum_admin_address       => $quantum_admin_address,
    	quantum_internal_address    => $quantum_internal_address,
    	quantum_port                => $quantum_port,
    	quantum_region              => $quantum_region,
    	l3_interface_driver         => $l3_interface_driver,
    	l3_use_namespaces           => $l3_use_namespaces,
    	l3_metadata_ip              => $l3_metadata_ip,
    	l3_external_network_bridge  => $l3_external_network_bridge,
    	l3_root_helper              => $l3_root_helper,
    	dhcp_state_path             => $dhcp_state_path,
    	dhcp_interface_driver       => $dhcp_interface_driver,
    	dhcp_driver                 => $dhcp_driver,
    	dhcp_use_namespaces         => $dhcp_use_namespaces,
    }

    class { "naginator::control_target":
    }

}

class compute(
  $internal_ip, 
  $crosstalk_ip,
  $public_interface   = $::public_interface,
  $private_interface  = $::private_interface,
  $internal_address   = $internal_ip,
  $libvirt_type       = $::libvirt_type,
  $fixed_range        = $::fixed_network_range,
  $network_manager    = 'nova.network.quantum.manager.QuantumManager',
  $multi_host         = $::multi_host,
  $sql_connection     = $::sql_connection,
  $nova_user_password = $::nova_user_password,
  $rabbit_host        = $::controller_node_internal,
  $rabbit_password    = $::rabbit_password,
  $rabbit_user        = $::rabbit_user,
  $glance_api_servers = "${::controller_node_internal}:9292",
  $vncproxy_host      = $::controller_node_public,
  $vnc_enabled        = 'true',
  $verbose            = $::verbose,
  $manage_volumes     = true,
  $nova_volume        = 'nova-volumes',
  # quantum config
  $quantum_enabled			= false,
  $quantum_url             	= "http://${::controller_node_address}:9696",
  $quantum_admin_tenant_name    	= 'services',
  $quantum_admin_username       	= 'quantum',
  $quantum_admin_password       	= 'quantum',
  $quantum_admin_auth_url       	= "http://${::controller_node_address}:35357/v2.0",
  $quantum_ip_overlap              = false,
  $libvirt_vif_driver      	= 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver',
  $libvirt_use_virtio_for_bridges  = 'True',
  $host        	 		= 'compute',
  #quantum general
  $quantum_log_verbose          	= "False",
  $quantum_log_debug            	= false,
  $quantum_bind_host            	= "0.0.0.0",
  $quantum_bind_port            	= "9696",
  $quantum_sql_connection       	= "mysql://quantum:quantum@${::controller_node_address}/quantum",
  $quantum_auth_host            	= "${::controller_node_address}",
  $quantum_auth_port            	= "35357",
  $quantum_rabbit_host          	= "${::controller_node_address}",
  $quantum_rabbit_port          	= "5672",
  $quantum_rabbit_user          	= "${::rabbit_user}",
  $quantum_rabbit_password      	= "${::rabbit_password}",
  $quantum_rabbit_virtual_host  	= "/",
  $quantum_control_exchange     	= "quantum",
  $quantum_core_plugin            	= "quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2",
  $quantum_mac_generation_retries 	= 16,
  $quantum_dhcp_lease_duration    	= 120,
  #quantum ovs
  $ovs_bridge_uplinks      	= ["br-ex:${::external_interface}"],
  $ovs_bridge_mappings      	= ['default:br-ex'],
  $ovs_tenant_network_type  	= "gre",
  $ovs_network_vlan_ranges  	= "default:1000:2000",
  $ovs_integration_bridge   	= "br-int",
  $ovs_enable_tunneling    	= "True",
  $ovs_tunnel_bridge       	= "br-tun",
  $ovs_tunnel_id_ranges     	= "1:1000",
  $ovs_local_ip             	= $crosstalk_ip,
  $ovs_server               	= false,
  $ovs_root_helper          	= "sudo quantum-rootwrap /etc/quantum/rootwrap.conf",
  $ovs_sql_connection       	= "mysql://quantum:quantum@${::controller_node_address}/quantum",
  ) 

    {

        # Optionally assign an interface address to an OVS port
        if ($::numbered_vs_port == 'true') {
            class { numbered_vs_port: pair => 'br-int:$::public_interface'}
        } elsif ($::numbered_vs_port != '') {
            class { numbered_vs_port: pair => '$::numbered_vs_port'}
        }

    class { 'openstack::compute':
		public_interface               => $public_interface,
		private_interface              => $private_interface,
		internal_address               => $internal_address,
		libvirt_type                   => $libvirt_type,
		fixed_range                    => $fixed_range,
		network_manager                => $network_manager,
		multi_host                     => $multi_host,
		sql_connection                 => $sql_connection,
		nova_user_password             => $nova_user_password,
		rabbit_host                    => $rabbit_host,
		rabbit_password                => $rabbit_password,
		rabbit_user                    => $rabbit_user,
		glance_api_servers             => $glance_api_servers,
		vncproxy_host                  => $vncproxy_host,
		vnc_enabled                    => $vnc_enabled,
		verbose                        => $verbose,
		manage_volumes                 => $manage_volumes,
		nova_volume                    => $nova_volume,
		quantum_enabled                => $quantum_enabled,
		quantum_url                    => $quantum_url,
		quantum_admin_tenant_name      => $quantum_admin_tenant_name,
		quantum_admin_username         => $quantum_admin_username,
		quantum_admin_password         => $quantum_admin_password,
		quantum_admin_auth_url         => $quantum_admin_auth_url,
		quantum_ip_overlap             => $quantum_ip_overlap,
		libvirt_vif_driver             => $libvirt_vif_driver,
		libvirt_use_virtio_for_bridges => $libvirt_use_virtio_for_bridges,
		host                           => $host,
		quantum_log_verbose            => $quantum_log_verbose,
		quantum_log_debug              => $quantum_log_debug,
		quantum_bind_host              => $quantum_bind_host,
		quantum_bind_port              => $quantum_bind_port,
		quantum_sql_connection         => $quantum_sql_connection,
		quantum_auth_host              => $quantum_auth_host,
		quantum_auth_port              => $quantum_auth_port,
		quantum_rabbit_host            => $quantum_rabbit_host,
		quantum_rabbit_port            => $quantum_rabbit_port,
		quantum_rabbit_user            => $quantum_rabbit_user,
		quantum_rabbit_password        => $quantum_rabbit_password,
		quantum_rabbit_virtual_host    => $quantum_rabbit_virtual_host,
		quantum_control_exchange       => $quantum_control_exchange,
		quantum_core_plugin            => $quantum_core_plugin,
		quantum_mac_generation_retries => $quantum_mac_generation_retries,
		quantum_dhcp_lease_duration    => $quantum_dhcp_lease_duration,
		ovs_bridge_uplinks             => $ovs_bridge_uplinks,
		ovs_bridge_mappings            => $ovs_bridge_mappings,
		ovs_tenant_network_type        => $ovs_tenant_network_type,
		ovs_network_vlan_ranges        => $ovs_network_vlan_ranges,
		ovs_integration_bridge         => $ovs_integration_bridge,
		ovs_enable_tunneling           => $ovs_enable_tunneling,
		ovs_tunnel_bridge              => $ovs_tunnel_bridge,
		ovs_tunnel_id_ranges           => $ovs_tunnel_id_ranges,
		ovs_local_ip                   => $ovs_local_ip,
		ovs_server                     => $ovs_server,
		ovs_root_helper                => $ovs_root_helper,
		ovs_sql_connection             => $ovs_sql_connection,
    }

    class { "naginator::compute_target":
    }

}


########### Definition of the Build Node #######################
#
# Definition of this node should match the name assigned to the build node in your deployment.
# In this example we are using build-node, you dont need to use the FQDN. 
#
node master-node inherits "cobbler-node" {
    $build_node_fqdn = "${::build_node_name}.${::domain_name}"

    host { $build_node_fqdn: 
	ip => $::cobbler_node_ip,
        host_aliases => ["${::build_node_name}", "puppet", "puppet.${::domain_name}"]
    }

    # Change the servers for your NTP environment
    # (Must be a reachable NTP Server by your build-node, i.e. ntp.esl.cisco.com)
    class { ntp:
	servers 	=> $::ntp_servers,
	ensure 		=> running,
	autoupdate 	=> true,
    }

    class { 'naginator':
    }

    class { 'graphite': 
	graphitehost 	=> $build_node_fqdn,
    }

    class { 'coe::site_index':
    }

    # set up a local apt cache.  Eventually this may become a local mirror/repo instead
    class { apt-cacher-ng: 
  	proxy 		=> $::proxy,
	avoid_if_range  => true, # Some proxies have issues with range headers
                                 # this stops us attempting to use them
                                 # msrginally less efficient with other proxies
    }

    if ! $::default_gateway {
        # Prefetch the pip packages and put them somewhere the openstack nodes can fetch them
        
        file {  "/var/www":
            ensure => 'directory',
        }

        file {  "/var/www/packages":
            ensure  => 'directory',
            require => File['/var/www'],
        }

        if($::proxy) {
            $proxy_pfx = "/usr/bin/env http_proxy=${::proxy} https_proxy=${::proxy} "
        } else {
            $proxy_pfx=""
        }
        exec { 'pip2pi':
            # Can't use package provider because we're changing its behaviour to use the cache
            command => "${proxy_pfx}/usr/bin/pip install pip2pi",
            creates => "/usr/local/bin/pip2pi",
            require => Package['python-pip'],
        }
        Package <| provider=='pip' |> {
            require => Exec['pip-cache']
        }
        exec { 'pip-cache':
            # All the packages that all nodes - build, compute and control - require from pip
            command => "${proxy_pfx}/usr/local/bin/pip2pi /var/www/packages collectd xenapi django-tagging graphite-web carbon whisper",
            creates => '/var/www/packages/simple', # It *does*, but you'll want to force a refresh if you change the line above
            require => Exec['pip2pi'],
        }
    }

    # set the right local puppet environment up.  This builds puppetmaster with storedconfigs (a nd a local mysql instance)
    class { puppet:
	run_master 		=> true,
	puppetmaster_address 	=> $build_node_fqdn, 
	certname 		=> $build_node_fqdn,
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

