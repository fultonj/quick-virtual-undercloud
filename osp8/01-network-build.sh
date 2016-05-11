#!/usr/bin/env bash

cat /dev/null > /tmp/net
echo "api|virbr1|52:54:00:e1:01:42|192.168.2.254" >> /tmp/net
echo "tenant|virbr2|52:54:00:e2:01:42|192.168.3.254" >> /tmp/net
echo "storage|virbr3|52:54:00:e3:01:42|172.16.1.254" >> /tmp/net
echo "storage-mgmt|virbr4|52:54:00:e4:01:42|172.16.2.254" >> /tmp/net

for line in $(cat /tmp/net); do 
    name=$(echo $line | awk 'BEGIN { FS = "|" } ; { print $1 }')
    bridge=$(echo $line | awk 'BEGIN { FS = "|" } ; { print $2 }')
    mac=$(echo $line | awk 'BEGIN { FS = "|" } ; { print $3 }')
    ip=$(echo $line | awk 'BEGIN { FS = "|" } ; { print $4 }')

    cat /dev/null > /tmp/net.xml
    echo "<network>" >> /tmp/net.xml
    echo "<name>$name</name>" >> /tmp/net.xml
    echo "<bridge name='$bridge' stp='off' delay='0'/>" >> /tmp/net.xml
    echo "<mac address='$mac'/>" >> /tmp/net.xml
    echo "<ip address='$ip' netmask='255.255.255.0'>" >> /tmp/net.xml
    echo "</ip>" >> /tmp/net.xml
    echo "</network>" >> /tmp/net.xml
    
    sudo virsh net-define /tmp/net.xml
    sudo virsh net-start $name
    sudo virsh net-autostart $name
done

sudo virsh net-list
sudo brctl show
