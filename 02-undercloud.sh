echo "ASSIGN A STATIC IP ADDRESS TO THE UNDERCLOUD"
sed -i s/ONBOOT=.*/ONBOOT=no/g /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i s/BOOTPROTO=.*/BOOTPROTO=static/g /etc/sysconfig/network-scripts/ifcfg-eth1
echo "IPADDR=192.168.122.253" >> /etc/sysconfig/network-scripts/ifcfg-eth1
echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-eth1
echo "GATEWAY=192.168.122.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-eth1
echo "DNS1=192.168.122.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
shutdown -h now
