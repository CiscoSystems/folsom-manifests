# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address

define cobbler_node($node_type, $mac, $ip, $power_address, $power_id = undef, 
  $power_user = 'admin', $power_password = 'password', $power_type = 'ipmitool' ) {
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
    log_host       => "{{ job.logging.host }}",
    log_port       => "{{ job.logging.port }}",
  }
}

node /cobbler-node/ inherits "base" {


####### Shared Variables from Site.pp #######
$cobbler_node_fqdn 	        = "${::build_node_name}.${::domain_name}"

if ($::interface_bonding == 'true'){
  $bonding = "echo 'bonding' >> /target/etc/modules ; \\"
} else {
  $bonding = ''
}

if ($::node_gateway) {
    $final_ifconf = "`tail +11 </etc/network/interfaces`"
} else {
    $final_ifconf = "`tail +11 </etc/network/interfaces | grep -v gateway`"
}

# Be aware this template will not know the address of the machine for which it's writing an interface file.  It's a 'feature'.
# The subst puts it all on one line, which makes the .ini file happy.
# Shell interpolation will happen to its contents.
$interfaces_file=regsubst(template("interfaces.erb"), '$', "\\n\\", "G")

if ($::ipv6_ra == "") {
  $ra='0'
} else {
  $ra = $::ipv6_ra 
}

####### Preseed File Configuration #######
 cobbler::ubuntu::preseed { "cisco-preseed":
  admin_user 		=> $::admin_user,
  password_crypted 	=> $::password_crypted,
  packages 		=> "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server 		=> $cobbler_node_fqdn,

  late_command => sprintf('
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a runinterval=300" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=%s" -i /target/etc/puppet/puppet.conf ; \
in-target /usr/sbin/ntpdate %s ; in-target /sbin/hwclock --systohc ; \
echo "*.* @{{ job.logging.host }}:{{ job.logging.port }}" > /target/etc/rsyslog.d/99-remote.conf ; \
echo "net.ipv6.conf.default.autoconf=%s" >> /target/etc/sysctl.conf ; \
echo "net.ipv6.conf.default.accept_ra=%s" >> /target/etc/sysctl.conf ; \
echo "net.ipv6.conf.all.autoconf=%s" >> /target/etc/sysctl.conf ; \
echo "net.ipv6.conf.all.accept_ra=%s" >> /target/etc/sysctl.conf ; \
echo "8021q" >> /target/etc/modules ; \
%s \
ifconf=%s ; \
echo -e "%s
" > /target/etc/network/interfaces ; \
', $cobbler_node_fqdn, $cobbler_node_fqdn, $ra,$ra,$ra,$ra, $bonding, $final_ifconf, $interfaces_file),
#  proxy 		=> "http://${cobbler_node_fqdn}:3142/",
  expert_disk 		=> true,
  diskpart 		=> [$::install_drive],
  boot_disk 		=> $::install_drive,
  autostart_puppet      => $::autostart_puppet,
  time_zone             => $::time_zone
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
  ucsm_port             => $::ucsm_port,
}

# This will load the Ubuntu Server OS into cobbler
# COE supprts only Ubuntu precise x86_64
 cobbler::ubuntu { "{{ job.description.ubuntu_series }}":
  proxy => $::proxy,
 }
}
