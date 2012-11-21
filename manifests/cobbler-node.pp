#
# == Example
#
# add this to your site.pp file:
# import "cobbler-node"
# in your site.pp file, add a node definition like:
# node 'cobbler.example.com' inherits cobbler-node { }
#

# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address
# If you are not using UCS blades, don't worry about the org-EXAMPLE, and if you are
# and aren't using an organization domain, just leave the value as ""
# An example MD5 crypted password is ubuntu: $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62t
#HDGB36EhiKF1
# which is used by the cobbler preseed file to set up the default admin user.

$cobbler_node_ip = "172.29.74.196"

node /cobbler-node/ {

 class { cobbler:
  node_subnet => '172.29.74.0',
  node_netmask => '255.255.254.0',
  node_gateway => '172.29.74.1',
  node_dns => "${cobbler_node_ip}",
  ip => "${cobbler_node_ip}",
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '172.29.74.194',
  dhcp_ip_high => '172.29.74.205',
  domain_name => 'ctocllab.cisco.com',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

# This will load the Ubuntu precise x86_64 server iso into cobbler
 cobbler::ubuntu { "precise":
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server => "build-node.ctocllab.cisco.com",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=build-node.ctocllab.cisco.com" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 172.29.74.1 iburst" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.40\niface eth0.40 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.40 0.0.0.0 up\n" 
>> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sdc'],
  boot_disk => '/dev/sdc',
 }

# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed bu
#ilt above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a
# static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, th
#e same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or se
#rvice profile name (in UCSM based deployements)

cobbler::node { "p5-control01":
 mac => "A4:4C:11:13:98:4F",
 profile => "precise-x86_64-auto",
 ip => "172.29.74.194",
 domain => "ctocllab.cisco.com",
 node_type => "control",
 preseed => "cisco-preseed",
 power_address => "172.29.74.170",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "p5-compute01":
 mac => "A4:4C:11:13:56:74",
 profile => "precise-x86_64-auto",
 ip => "172.29.74.197",
 domain => "ctocllab.cisco.com",
 node_type => "compute",
 preseed => "cisco-preseed",
 power_address => "172.29.74.173",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
}
# Repeat as necessary. 
}
