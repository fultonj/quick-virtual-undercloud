#!/usr/bin/env bash
# -------------------------------------------------------
undercloud_name="undercloud"
undercloud_qcow=$undercloud_name.qcow2
undr=192.168.122.253
cwd=/home/jfulton/git/hub/quick-virtual-undercloud
hci=/home/jfulton/git/lab/hci0
# -------------------------------------------------------
if [[ $(whoami) != "root" ]]; 
    then 
    echo "This must be run as root on your testing hypervisor";
    exit 1
fi
# -------------------------------------------------------
if [[ ! -e ~/.ssh/id_rsa.pub ]]; then
    if [[ ! -e /home/jfulton/.ssh/id_rsa.pub ]]; then
	echo "Neither jfulton's nor root's id_rsa.pub exist; exiting."
	exit 1
    else
	cp -f /home/jfulton/.ssh/id_rsa.pub ~/.ssh/id_rsa.pub
	chmod 0600 ~/.ssh/id_rsa.pub
    fi
fi
key=$(cat ~/.ssh/id_rsa.pub)

# -------------------------------------------------------
echo "Configuring ~/.ssh/config to not prompt for non-matching keys and not manage keys via known_hosts"
cat /dev/null > ~/.ssh/config
echo "StrictHostKeyChecking no" >> ~/.ssh/config
echo "UserKnownHostsFile=/dev/null" >> ~/.ssh/config
echo "LogLevel ERROR" >> ~/.ssh/config
chmod 0600 ~/.ssh/config
chmod 0700 ~/.ssh/
# -------------------------------------------------------
echo "Destroying $undercloud_name"
virsh destroy $undercloud_name
virsh undefine $undercloud_name
rm -f /var/lib/libvirt/images/$undercloud_qcow

echo "Building a new $undercloud_name"
# -------------------------------------------------------
full_qcow_name=/var/lib/libvirt/images/rhel-guest-image-7.2-20151102.0.x86_64.qcow2
img=$(basename $full_qcow_name)
pushd /var/lib/libvirt/images/

qemu-img info $img
virt-filesystems --long -h --all -a $img
qemu-img resize $img +30G
virt-customize -a $img --run-command 'echo -e "d\nn\n\n\n\n\nw\n" | fdisk /dev/sda'
virt-customize -a $img --run-command 'xfs_growfs /'
virt-filesystems --long -h --all -a $img 
virt-customize -a $img --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,1} && sed -i s/DEVICE=.*/DEVICE=eth1/g /etc/sysconfig/network-scripts/ifcfg-eth1'

qemu-img create -f qcow2 -b $img $undercloud_qcow

virt-customize -a $undercloud_qcow --run-command 'yum remove cloud-init* -y'
virt-customize -a $undercloud_qcow --root-password password:Redhat01
virt-customize -a $undercloud_qcow  --hostname undercloud.example.com

virt-customize -a $undercloud_qcow --run-command 'sed -i -e "s/BOOTPROTO=.*/BOOTPROTO=none/g" -e "s/BOOTPROTOv6=.*/NM_CONTROLLED=no/g" -e "s/USERCTL=.*/IPADDR=192.168.122.253/g" -e "s/PEERDNS=.*/NETMASK=255.255.255.0/g" -e "s/IPV6INIT=.*/GATEWAY=192.168.122.1/g" -e "s/PERSISTENT_DHCLIENT=.*/DEFROUTE=yes/g" /etc/sysconfig/network-scripts/ifcfg-eth1'

virt-customize -a $undercloud_qcow --run-command "mkdir /root/.ssh/; chmod 700 /root/.ssh/; echo $key > /root/.ssh/authorized_keys; chmod 600 /root/.ssh/authorized_keys; chcon system_u:object_r:ssh_home_t:s0 /root/.ssh ; chcon unconfined_u:object_r:ssh_home_t:s0 /root/.ssh/authorized_keys "

virt-install --ram 6144 --vcpus 4 --os-variant rhel7 --disk path=/var/lib/libvirt/images/$undercloud_qcow,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network network:provisioning --network network:default --network network:tenant --network network:storage --name $undercloud_name

sleep 10
if [[ ! $(virsh list | grep undercloud) ]]; then
    echo "Cannot find new undercloud VM; Exiting."
    echo 1
fi

echo "Waiting for $undercloud_name to boot and allow to SSH at $undr"
while [[ ! $(ssh root@$undr "uname") ]]
do
    echo "No route to host yet; sleeping 30 seconds"
    sleep 30
done
echo "SSH to $undr is working."

#mac=$(virsh domiflist $undercloud_name | awk '/default/ {print $5};')
#ip=$(arp -n | grep $mac | awk {'print $1'})

echo "Updating /etc/hosts"
ssh root@$undr 'echo "192.168.122.253    undercloud.example.com        undercloud" >> /etc/hosts'
ssh root@$undr 'echo "192.168.122.252 ntp.example.com ntp" >> /etc/hosts'
ssh root@$undr 'echo "192.168.122.1      runcible.example.com          runcible" >> /etc/hosts'

echo "Updating /etc/chrony.conf and restarting chronyc"
ssh root@$undr "cat /dev/null > /etc/chrony.conf"
ssh root@$undr "echo 'server ntp.example.com iburst' >> /etc/chrony.conf"
ssh root@$undr "echo 'driftfile /var/lib/chrony/drift' >> /etc/chrony.conf"
ssh root@$undr "echo 'logdir /var/log/chrony' >> /etc/chrony.conf"
ssh root@$undr "echo 'log measurements statistics tracking' >> /etc/chrony.conf"
ssh root@$undr "systemctl enable chronyd.service"
ssh root@$undr "systemctl stop chronyd.service"
ssh root@$undr "systemctl start chronyd.service"
ssh root@$undr "systemctl status chronyd.service"
ssh root@$undr "chronyc sources"

echo "Creating stack user"
ssh root@$undr 'useradd stack'
ssh root@$undr 'echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack'
ssh root@$undr 'chmod 0440 /etc/sudoers.d/stack'
ssh root@$undr "mkdir /home/stack/.ssh/; chmod 700 /home/stack/.ssh/; echo $key > /home/stack/.ssh/authorized_keys; chmod 600 /home/stack/.ssh/authorized_keys; chcon system_u:object_r:ssh_home_t:s0 /home/stack/.ssh ; chcon unconfined_u:object_r:ssh_home_t:s0 /home/stack/.ssh/authorized_keys; chown -R stack:stack /home/stack/.ssh/ "

echo "Copying up mac addresses of 'baremetal' nodes as ~/macs.txt on $undr"
scp /tmp/nodes.txt stack@$undr:/home/stack/macs.txt

echo "Copying up a copy of this git repo so the next set of scripts may be run on $undr"
scp -r $cwd/ stack@$undr:/home/stack/

echo "Copying up a copy of my hci repo so the next set of scripts may be run on $undr"
scp -r $hci/ stack@$undr:/home/stack/

echo "$undr is ready"
ssh root@$undr "uname -a"
echo ""
echo "ssh -A stack@$undr"
echo ""
exit 0

