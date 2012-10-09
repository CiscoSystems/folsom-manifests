Building the environment
------------------------

1) Build an Ubuntu 12.04 system.

Install a ubuntu-based linux server with openssh-server enabled. The rest of the packages and dependencies will
be installed automatically by puppet. We are in the process of providing a Virtual Machine (VM) to be used as
build node but in thge meantime you will need to install your own build server manually.

2) Add the necessary packages to have puppet running and cisco edition enabled

	apt-get update && apt-get dist-upgrade -y

Note: The system will need to be restarted after applying the updates.

You will need a couple additional packages:

	apt-get install -y python-software-properties
	apt-get install ntp puppet git ipmitool -y

Get the Cisco Edition packages from the following repo:

	git clone --recursive -b folsom https://github.com/CiscoSystems/puppet-root.git ~/folsom/

Copy all the content under ~/folsom/modules/ to /etc/puppet/modules/

	cp -r ~/folsom/modules/ /etc/puppet/modules/

Optional: If you have your set up behind a proxy, you should export your proxy configuration:

	export http_proxy=http://proxy.esl.cisco.com:80
	export https_proxy=https://proxy.esl.cisco.com:80

Optional: If your set up is in a private network and your build node will act as proxy server, you need to add
the corresponding NAT and forwarding configuration.

	iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
	iptables --append FORWARD --in-interface eth1 -j ACCEPT
	echo 1 > /proc/sys/net/ipv4/ip_forward


Customizing your environment
------------------------


YOU MUST THEN EDIT THESE FILES.  They are fairly well documented, but please comment with questions. You can also 
read through these descriptions: [Cobbler Node](https://github.com/CiscoSystems/folsom-manifests/blob/simple-multi-node/Cobbler-Node.md)  and [Site](https://github.com/CiscoSystems/folsom-manifests/blob/simple-multi-node/Site.md)

Then 'puppet apply' it:

	puppet apply -v /etc/puppet/manifests/site.pp

I recommend a reboot at this point, as it seems that the puppetmaster doesn't restart correctly otherwise.

And now you should be able to load up your cobbled nodes:

	~/os-docs/examples/clean_node.sh {node_name} example.com

or if you want to do it for _all_ of the nodes defined in your cobbler-node.pp file:

	for n in `cobbler system list`; do ~/os-docs/examples/clean_node.sh $n example.com ; done

_note: replace example.com with your nodes proper domain name._

Testing OpenStack
-----------------

Once the nodes are built, and once puppet runs (watch /var/log/syslog on the cobbler node), you should be able to 
log into the openstack horizon interface:

http://ip-of-your-control-node
user: admin, password: Cisco123 (if you didn't change the defaults in the site.pp file)

you will still need to log into the console of the control node to load in an image:
user: localadmin, password: ubuntu.  If you SU to root, there is an openrc auth file in root's home directory, and
 you can launch a test file in /tmp/nova_test.sh.

You should now have a cirros image and a running instance (called dans_vm if you didn't change anything).


