echo "DESTROYING OVERCLOUD"
echo "I should be on the undercloud node as the stack user"
whoami
source ~/stackrc

echo "deleting the overcloud heat stack"
heat stack-list
heat stack-delete overcloud
heat stack-list

echo "bare metal nodes should now be available"
ironic node-list

