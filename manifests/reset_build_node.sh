#!/bin/bash
#
# revert build node to "clean" state

for j in nagios collectd cobbler dnsmasq puppet passenger apache2 mysql
do
    echo "Purging $j"
    for i in `dpkg -l | grep "$j" | awk '{ print $2 }'`
    do
        apt-get purge -y "$i"
    done
done

apt-get --purge autoremove -y

rm -rf /etc/mysql /var/lib/mysql /var/lib/puppet /var/lib/cobbler /root/.my.cnf /etc/nagios3 /etc/nagios /var/www/index.html /var/www/header-logo.png /etc/cobbler /etc/apache2
