echo "MANUALLY DISABLE DHCP FOR THE VIRSH DEFAULT NETWORK"
echo "virsh net-edit default; virsh net-destroy default; virsh net-start default; virsh net-dumpxml default"
echo -e "192.168.122.253\t\tundercloud.redhat.local\tundercloud" >> /etc/hosts
virsh start undercloud
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
ssh-copy-id -i ~/.ssh/id_rsa.pub root@undercloud
echo "ssh root@undercloud"
