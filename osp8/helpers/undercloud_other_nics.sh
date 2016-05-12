#!/usr/bin/env bash
for x in eth2:192.168.2.1 eth3:192.168.3.1 eth4:172.16.1.1 eth5:172.16.2.1 ; do 
    dev=$(echo $x | awk 'BEGIN { FS = ":" } ; { print $1 }')
    ip=$(echo $x | awk 'BEGIN { FS = ":" } ; { print $2 }')
    cat /dev/null > /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "DEVICE=$dev" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "IPADDR=$ip" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-$dev
    ifup $dev
    ip a s $dev
done
