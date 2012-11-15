# == Example ===
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
# An example MD5 crypted password is ubuntu: $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
# which is used by the cobbler preseed file to set up the default admin user.

$cobbler_node_ip = "192.168.150.254"

node /cobbler-node/ {

 class { cobbler:
  node_subnet => '192.168.150.0',
  node_netmask => '255.255.255.0',
  node_gateway => '192.168.150.254',
  node_dns => '192.168.150.254',
  ip => '192.168.150.254',
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.150.100',
  dhcp_ip_high => '192.168.150.150',
  domain_name => 'cisco.openstack.com',
  proxy => 'http://192.168.150.254:3142/',
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

# This will load the Ubuntu precise x86_64 server iso into cobbler
 cobbler::ubuntu { "precise":
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server => "192.168.150.254",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a runinterval=300" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=build-node.cisco.openstack.com" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 192.168.150.254 iburst" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.40\niface eth0.40 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.40 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
true
',
  proxy => 'http://192.168.150.254:3142/',
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sdc'],
  boot_disk => '/dev/sdc',
 }

# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed built above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, the same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or service profile name (in UCSM based deployements)

cobbler::node { "control":
 mac => "00:10:18:65:C9:BC",
 profile => "precise-x86_64-auto",
 ip => "192.168.150.11",
 domain => "cisco.openstack.com",
 preseed => "cisco-preseed",
 power_address=>"172.20.231.46",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "c3l123",
 }


cobbler::node { "compute01":
 mac => "00:10:18:65:C7:80",
 profile => "precise-x86_64-auto",
 ip => "192.168.150.12",
 domain => "cisco.openstack.com",
 preseed => "cisco-preseed",
 power_address => "172.20.231.47",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "c3l123",
 }

# Repeat as necessary.
}

