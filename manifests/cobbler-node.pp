# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address

define cobbler_node($node_type, $mac, $ip, $power_address, $power_id = undef, 
  $power_user => 'admin', power_password => 'password', power_type => 'ipmitool' ) {
  cobbler::node { $name:
    mac            => $mac,
    ip             => $ip,
    ### UCS CIMC Details ###
    # Change these parameters to match the management console settings for your server
    power_address  => $power_address,
    power_user     => $power_user,
    power_password => $power_password,
    power_type     => $power_type,
    power_id       => $power_id,
    ### Advanced Users Configuration ###
    # These parameters typically should not be changed
    profile        => "precise-x86_64-auto",
    domain         => $::domain_name,
    node_type      => $node_type,
    preseed        => "cisco-preseed",
  }
}

node /cobbler-node/ inherits "base" {


####### Shared Variables from Site.pp #######
$cobbler_node_fqdn 	        = "${::build_node_name}.${::domain_name}"

####### Preseed File Configuration #######
 cobbler::ubuntu::preseed { "cisco-preseed":
  admin_user 		=> $::admin_user,
  password_crypted 	=> $::password_crypted,
  packages 		=> "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server 		=> $::build_node_fqdn,
  late_command 		=> "sed -e '/logdir/ a pluginsync=true' -i /target/etc/puppet/puppet.conf ; \
	sed -e \"/logdir/ a server=$cobbler_node_fqdn\" -i /target/etc/puppet/puppet.conf ; \
	echo -e \"server $cobbler_node_fqdn iburst\" > /target/etc/ntp.conf ; \
	echo '8021q' >> /target/etc/modules ; \
	true
	",
  proxy 		=> "http://${cobbler_node_fqdn}:3142/",
  expert_disk 		=> true,
  diskpart 		=> [$::install_drive],
  boot_disk 		=> $::install_drive,
  autostart_puppet      => $::autostart_puppet
 }


class { cobbler: 
  node_subnet 		=> $::node_subnet, 
  node_netmask 		=> $::node_netmask,
  node_gateway 		=> $::node_gateway,
  node_dns 		=> $::node_dns,
  ip 			=> $::ip,
  dns_service 		=> $::dns_service,
  dhcp_service 		=> $::dhcp_service,
# change these two if a dynamic DHCP pool is needed
  dhcp_ip_low           => false,
  dhcp_ip_high          => false,
  domain_name 		=> $::domain_name,
  password_crypted 	=> $::password_crypted,
}

# This will load the Ubuntu Server OS into cobbler
# COE supprts only Ubuntu precise x86_64
 cobbler::ubuntu { "precise":
  proxy => $::proxy,
 }
}
