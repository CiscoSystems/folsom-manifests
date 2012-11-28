# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address

node /cobbler-node/ inherits "base" {

# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed built above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a
# static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, 
# the same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or
# service profile name (in UCSM based deployements)

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
 ### Advanced Users Confirgaution ###
 profile => "precise-x86_64-auto",
 domain => $::domain_name,
 node_type => "compute",
 preseed => "cisco-preseed",
 }

# Repeat as necessary.

###### Nothing needs to be manually edited from this point ######


####### Shared Variables from Site.pp #######
$cobbler_node_ip = $::build_node_fqdn
$BUILD-NODE = $::build_node_fqdn
$ETHER_VLAN = $::private_interface
$ETHERNET = $::public_interface

####### Preseed File Configuration #######
 cobbler::ubuntu::preseed { "cisco-preseed":
  admin_user => $::admin_user,
  password_crypted => $::password_crypted,
  packages => "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server => $::build_node_fqdn,
late_command => "
sed -e '/logdir/ a pluginsync=true' -i /target/etc/puppet/puppet.conf ; \
sed -e \"/logdir/ a server=$BUILD-NODE\" -i /target/etc/puppet/puppet.conf ; \
sed -e 's/START=no/START=yes/' -i /target/etc/default/puppet ; \
echo -e \"server $BUILD-NODE iburst\" > /target/etc/ntp.conf ; \
echo '8021q' >> /target/etc/modules ; \
echo \"# Private Interface\" >> /target/etc/network/interfaces ;\
echo \"auto $ETHER_VLAN\" >> /target/etc/network/interfaces ;\
echo \"iface $ETHER_VLAN inet manual\" >> /target/etc/network/interfaces ;\
echo \"      vlan-raw-device $ETHERNET\" >> /target/etc/network/interfaces ;\
echo \"      up ifconfig $ETHER_VLAN 0.0.0.0 up\" >> /target/etc/network/interfaces ; \
echo \" \" >> /target/etc/network/interfaces ; \
true
",
  proxy => "http://${cobbler_node_ip}:3142/",
  expert_disk => true,
  diskpart => ['/dev/sdc'],
  boot_disk => '/dev/sdc',
 }


class { cobbler: 
  node_subnet => $::node_subnet, 
  node_netmask => $::node_netmask,
  node_gateway => $::node_gateway,
  node_dns => $::node_dns,
  ip => $::ip,
  dns_service => $::dns_service,
  dhcp_service => $::dhcp_service,
  dhcp_ip_low => $::dhcp_ip_low,
  dhcp_ip_high => $::dhcp_ip_high, 
  domain_name => $::domain_name,
  proxy => $::cobbler_proxy,
  password_crypted => $::password_crypted,
}

# This will load the Ubuntu Server OS into cobbler
# COE supprts only Ubuntu precise x86_64
 cobbler::ubuntu { "precise":
 }
}
