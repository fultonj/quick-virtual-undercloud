echo "UPLOAD OVERCLOUD IAMGES TO GLANCE"
echo "Did you download the overcloud images and put them on the undercloud?"
whoami
cd ~/images
ls *.tar
for tarfile in *.tar; do tar -xf $tarfile; done
source ~/stackrc
openstack overcloud image upload --image-path /home/stack/images/
openstack image list
ls /httpboot -l

echo "SET DNS SERVER FOR PROVISIONING NETWORK"
neutron subnet-list
sub=`neutron subnet-list -f csv | tail -1 | awk 'BEGIN { FS = "," } ; { print $1 }' | sed s/\"//g`
neutron subnet-show $sub
neutron subnet-update $sub --dns-nameserver 8.8.8.8
echo "Create overcloud nodes with 07-hypervisor3.sh"
