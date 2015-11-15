echo "REMOVING OVERCLOUD VIRTUAL MACHINES"

virsh list --all

for i in $(virsh list --all | grep overcloud | awk {'print $2;'}); do virsh destroy $i; virsh undefine $i; rm -f /var/lib/libvirt/images/$i.qcow2; done 

virsh list --all

rm -f /tmp/nodes.txt /tmp/overcloud-node*
