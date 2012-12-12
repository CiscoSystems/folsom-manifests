# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address

node /cobbler-node/ inherits "base" {


####### Shared Variables from Site.pp #######
$cobbler_node_ip 	= $::build_node_fqdn
$BUILD-NODE 		= $::build_node_fqdn

####### Preseed File Configuration #######
 cobbler::ubuntu::preseed { "cisco-preseed":
  admin_user 		=> $::admin_user,
  password_crypted 	=> $::password_crypted,
  packages 		=> "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server 		=> $::build_node_fqdn,
  late_command 		=> "
	sed -e '/logdir/ a pluginsync=true' -i /target/etc/puppet/puppet.conf ; \
	sed -e \"/logdir/ a server=$BUILD-NODE\" -i /target/etc/puppet/puppet.conf ; \
	sed -e 's/START=no/START=yes/' -i /target/etc/default/puppet ; \
	echo -e \"server $BUILD-NODE iburst\" > /target/etc/ntp.conf ; \
	echo '8021q' >> /target/etc/modules ; \
	true
	",
  proxy 		=> "http://${cobbler_node_ip}:3142/",
  expert_disk 		=> true,
  diskpart 		=> [$::install_drive],
  boot_disk 		=> $::install_drive,
 }


class { cobbler: 
  node_subnet 		=> $::node_subnet, 
  node_netmask 		=> $::node_netmask,
  node_gateway 		=> $::node_gateway,
  node_dns 		=> $::node_dns,
  ip 			=> $::ip,
  dns_service 		=> $::dns_service,
  dhcp_service 		=> $::dhcp_service,
  domain_name 		=> $::domain_name,
  proxy 		=> $::cobbler_proxy,
  password_crypted 	=> $::password_crypted,
}

# This will load the Ubuntu Server OS into cobbler
# COE supprts only Ubuntu precise x86_64
 cobbler::ubuntu { "precise":
 }
}
