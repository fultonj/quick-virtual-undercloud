echo "CREATING OVERCLOUD VIRTUAL HARDWARE"
cd /var/lib/libvirt/images/
for i in {1..5}; do qemu-img create -f qcow2 -o preallocation=metadata overcloud-node$i.qcow2 60G; done
for i in {1..5}; do \
    virt-install --ram 4096 --vcpus 2 --os-variant rhel7 \
    --disk path=/var/lib/libvirt/images/overcloud-node$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default --name overcloud-node$i \
    --dry-run --print-xml > /tmp/overcloud-node$i.xml; \
    virsh define --file /tmp/overcloud-node$i.xml; done
virsh list --all


echo "SETTING UP IPMI SIMULATION VIA SSH_PXE"
useradd stack
echo "Redhat01" | passwd stack --stdin
cat << EOF > /etc/polkit-1/rules.d/50-libvirt.rules
polkit.addRule(function(action, subject) {
        if (action.id == 'org.libvirt.unix.manage' &&
                subject.user == 'stack') {
                        return polkit.Result.YES;
                }
});
EOF

echo "SETTING UP ARTIFICIAL IPMI"
echo "accept this key please..."
virsh --connect qemu+ssh://stack@192.168.122.1/system list --all

for i in {1..5}; do \
    mac=$(virsh domiflist overcloud-node$i | grep provisioning | awk '{print $5};'); \
    echo -e "$mac" >> /tmp/nodes.txt; done

scp /tmp/nodes.txt stack@undercloud:/tmp/nodes.txt

echo "Configure the undercloud next with 08-undercloud5.sh"
