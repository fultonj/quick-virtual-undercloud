#!/usr/bin/env bash
# -------------------------------------------------------
undercloud_name="undercloud"
undercloud_qcow=$undercloud_name.qcow2
undr=192.168.122.253
cwd=/home/jfulton/git/hub/quick-virtual-undercloud/osp8/helpers
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
	chmod 0644 ~/.ssh/id_rsa.pub
    fi
fi
key=$(cat ~/.ssh/id_rsa.pub)
# -------------------------------------------------------
echo "Destroying $undercloud_name"
virsh destroy $undercloud_name
virsh undefine $undercloud_name
rm -f /var/lib/libvirt/images/$undercloud_qcow

echo "Building a new $undercloud_name"
# -------------------------------------------------------
if [[ ! $(rpm -q rhel-guest-image-7) ]]; 
    then 
    subscription-manager repos --enable=rhel-7-server-rh-common-rpms
    yum install rhel-guest-image-7 -y
fi
# -------------------------------------------------------
full_qcow_name=$(ls /usr/share/rhel-guest-image-7/*.qcow2)
if [ ! $? -eq 0 ]; then 
    echo "Could not find RHEL7 image. Aborting"; 
    exit 1;
fi
img=$(basename $full_qcow_name)
cp $full_qcow_name /var/lib/libvirt/images/
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

virt-install --ram 4096 --vcpus 4 --os-variant rhel7 --disk path=/var/lib/libvirt/images/$undercloud_qcow,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network network:provisioning --network network:default --network network:api --network network:tenant --network network:storage --network network:storage-mgmt --name $undercloud_name

echo "Waiting for $undercloud_name to boot"
sleep 30

#mac=$(virsh domiflist $undercloud_name | awk '/default/ {print $5};')
#ip=$(arp -n | grep $mac | awk {'print $1'})

echo "pinging $undercloud_name at $undr"
ping -c 2 $undr

echo "Updating /etc/hosts"
ssh root@$undr 'echo "192.168.122.253    undercloud.example.com        undercloud" >> /etc/hosts'
ssh root@$undr 'echo "192.168.122.251 overcloud-ntp.example.com overcloud-ntp" >> /etc/hosts'
ssh root@$undr 'echo "192.168.122.1      runcible.example.com          runcible" >> /etc/hosts'

echo "Updating /etc/chrony.conf and restarting chronyc"
ssh root@$undr "cat /dev/null > /etc/chrony.conf"
ssh root@$undr "echo 'server 192.168.122.251 iburst' >> /etc/chrony.conf"
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

#echo "Copying up scripts to be run on $undr"
scp /tmp/nodes.txt stack@$undr:/home/stack/macs.txt
scp $cwd/repos.sh stack@$undr:/home/stack/
scp $cwd/ansible-install.sh stack@$undr:/home/stack/

echo "$undr is ready"
ssh root@$undr "uname -a"
echo ""
echo "ssh -A stack@$undr"
echo ""
exit 0

