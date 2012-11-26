# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address
# Default user is: localadmin
# An example MD5 crypted password is "ubuntu": $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
# which is used by the cobbler preseed file to set up the default admin user.


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

####### Shared Variables from Site.pp #######
$cobbler_node_ip = $::build_node_fqdn
notify{"inside cobbler-node  clobber_ip: ${cobbler_node_ip}": }

####### Preseed File Configuration #######
# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
# The following variables may be changed by the system admin:
# 1) admin_user
# 2) password_crypted
# 3) late_command (Must Replace "BUILD-NODE-FQDN" with the corresponding value)
 cobbler::ubuntu::preseed { "cisco-preseed":
  admin_user => "localadmin",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  packages => "openssh-server vim ntp puppet",
  ntp_server => $::build_node_fqdn,
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=build-node.ctocllab.cisco.com" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server build-node.ctocllab.cisco.com iburst" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.40\niface eth0.40 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.40 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
true
',
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
