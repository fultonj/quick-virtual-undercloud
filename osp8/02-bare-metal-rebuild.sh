#!/usr/bin/env bash
# -------------------------------------------------------
VM_COUNT='1 2'
#VM_COUNT='1 2 3 4 5'
DELETE=1
ADD=1
SSH_PXE=0
# -------------------------------------------------------
if [ $DELETE -eq 1 ]; then 
    echo "REMOVING OVERCLOUD VIRTUAL MACHINES"

    sudo virsh list --all

    for i in $(sudo virsh list --all | grep overcloud | awk {'print $2;'}); do 
	sudo virsh destroy $i; 
	sudo virsh undefine $i; 
	sudo rm -f /var/lib/libvirt/images/$i.qcow2; 
    done 

    sudo virsh list --all
fi
# -------------------------------------------------------
if [ $ADD -eq 1 ]; then 
    echo "CREATING OVERCLOUD VIRTUAL HARDWARE"
    pushd /var/lib/libvirt/images/
    for i in $(echo $VM_COUNT); do 
	sudo qemu-img create -f qcow2 -o preallocation=metadata overcloud-node$i.qcow2 60G; 
	sudo qemu-img create -f qcow2 -o preallocation=metadata overcloud-ceph-osd$i.qcow2 60G; 
    done
    popd

    for i in $(echo $VM_COUNT); do 
	sudo virt-install --ram 4608 --vcpus 2 --os-variant rhel7 \
	--disk path=/var/lib/libvirt/images/overcloud-node$i.qcow2,device=disk,bus=virtio,format=qcow2 \
	--disk path=/var/lib/libvirt/images/overcloud-ceph-osd$i.qcow2,device=disk,bus=virtio,format=qcow2 \
	--noautoconsole --vnc \
	--network network:provisioning \
	--network network:default \
	--network network:tenant \
	--network network:storage \
	--name overcloud-node$i \
	--dry-run --print-xml > /tmp/overcloud-node$i.xml; \

	sudo virsh define --file /tmp/overcloud-node$i.xml; 
    done
    sudo virsh list --all

fi
# -------------------------------------------------------
if [ $SSH_PXE -eq 1 ]; then 
    echo "SETTING UP IPMI SIMULATION VIA SSH_PXE"
    sudo useradd stack
    sudo echo "Redhat01" | passwd stack --stdin
    sudo cat << EOF > /etc/polkit-1/rules.d/50-libvirt.rules
polkit.addRule(function(action, subject) {
        if (action.id == 'org.libvirt.unix.manage' &&
                subject.user == 'stack') {
                        return polkit.Result.YES;
                }
});
EOF
    echo "SETTING UP ARTIFICIAL IPMI"
    echo "accept this key please..."
    sudo virsh --connect qemu+ssh://stack@192.168.122.1/system list --all
fi
# -------------------------------------------------------
