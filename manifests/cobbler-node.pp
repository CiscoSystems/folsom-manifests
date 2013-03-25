# This describes the hardware of the nodes to the extent required to network-install their
# OS.
# Change this to suit your hardware; the supplied configuration works for UCS models with CIMC
# using a default password.
# If you have multiple different hardware types or disk configurations you may need to use
# multiple block types here.
define cobbler_node($node_type, $mac, $ip, $power_address, $power_id = undef, $power_user = "admin", $power_password = "password") {
  cobbler::node { $name:
    mac 	   => $mac,
    ip 		   => $ip,
    ### UCS CIMC Details ###
    # Change these parameters to match the management console settings for your server
    power_address  => $power_address,
    power_user 	   => "admin",
    power_password => "password",
    power_type     => "ipmitool",
    power_id       => $power_id,
    ### Advanced Users Configuration ###
    # These parameters typically should not be changed
    profile 	   => "precise-x86_64-auto",
    domain         => $::domain_name,
    node_type 	   => $node_type,
    preseed 	   => "cisco-preseed",
  }
}

# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address

node /cobbler-node/ inherits "base" {


####### Shared Variables from Site.pp #######
$cobbler_node_fqdn 	        = "${::build_node_name}.${::domain_name}"

# Be aware this template will not know the address of the machine for which it's writing an interface file.  It's a 'feature'.
# The subst puts it all on one line, which makes the .ini file happy.
# Shell interpolation will happen to its contents.
$interfaces_file=regsubst(template("interfaces.erb"), '$', "\\n\\", "G")

####### Preseed File Configuration #######
 cobbler::ubuntu::preseed { "cisco-preseed":
  admin_user 		=> $::admin_user,
  password_crypted 	=> $::password_crypted,
  packages 		=> "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server 		=> $::cobbler_node_fqdn,
  late_command => sprintf('
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a runinterval=300" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=%s" -i /target/etc/puppet/puppet.conf ; \
in-target /usr/sbin/ntpdate %s ; in-target /sbin/hwclock --systohc ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo "8021q" >> /target/etc/modules ; \
echo "bonding" >> /target/etc/modules ; \
ifconf="`tail +11 </etc/network/interfaces`" ; \
echo -e "%s
" > /target/etc/network/interfaces ; \
true
', $::cobbler_node_fqdn, $::cobbler_node_fqdn, $interfaces_file),
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
