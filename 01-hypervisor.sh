echo "PUT THE IMAGES IN PLACE"
echo "Download three ironic images from https://access.redhat.com/downloads/content/191/ver=7/rhel---7/7/x86_64/product-downloads"
echo "Download the KVM image from https://access.redhat.com/downloads/content/69/ver=/rhel---7/7.2%20Beta/x86_64/product-downloads"
echo "Put the KVM image in /var/lib/libvirt/images/rhel-guest-image-7.2-20150821.0.x86_64.qcow2" 

echo "INSTALL KVM"
yum install libvirt qemu-kvm virt-manager virt-install libguestfs-tools -y 
yum install xorg-x11-apps xauth virt-viewer -y

echo "CREATE A PVORIONING NETWORK"
cat > /tmp/provisioning.xml <<EOF
<network>
  <name>provisioning</name>
  <ip address="172.16.0.254" netmask="255.255.255.0"/>
</network>
EOF

virsh net-define /tmp/provisioning.xml
virsh net-autostart provisioning
virsh net-start provisioning

echo "MODIFY OUR CLOUD IMAGE SO IT CAN HOST THE UNDERCLOUD"
pushd /var/lib/libvirt/images
qemu-img info rhel-guest-image-7.2-20150821.0.x86_64.qcow2
virt-filesystems --long -h --all -a rhel-guest-image-7.2-20150821.0.x86_64.qcow2
qemu-img resize rhel-guest-image-7.2-20150821.0.x86_64.qcow2 +30G
virt-customize -a rhel-guest-image-7.2-20150821.0.x86_64.qcow2 --run-command 'echo -e "d\nn\n\n\n\n\nw\n" | fdisk /dev/sda'
virt-customize -a rhel-guest-image-7.2-20150821.0.x86_64.qcow2 --run-command 'xfs_growfs /'
virt-filesystems --long -h --all -a rhel-guest-image-7.2-20150821.0.x86_64.qcow2 
virt-customize -a rhel-guest-image-7.2-20150821.0.x86_64.qcow2 --run-command 'cp /etc/sysconfig/network-scripts/ifcfg-eth{0,1} && sed -i s/DEVICE=.*/DEVICE=eth1/g /etc/sysconfig/network-scripts/ifcfg-eth1'
qemu-img create -f qcow2 -b rhel-guest-image-7.2-20150821.0.x86_64.qcow2 undercloud.qcow2
virt-customize -a undercloud.qcow2 --run-command 'yum remove cloud-init* -y'
virt-customize -a undercloud.qcow2 --root-password password:Redhat01
virt-customize -a undercloud.qcow2 --run-command 'rpm -ivh http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm && rhos-release 7-director'
virt-install --ram 8192 --vcpus 4 --os-variant rhel7 --disk path=/var/lib/libvirt/images/undercloud.qcow2,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network network:provisioning  --network network:default --name undercloud 
mac=$(virsh domiflist undercloud | awk '/default/ {print $5};')
echo "ssh into the undercloud and run 02-undercloud.sh there"


