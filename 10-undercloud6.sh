echo "UPDATING TIMEOUTS"
sudo su -
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_response_timeout 600
openstack-config --set /etc/ironic/ironic.conf DEFAULT rpc_response_timeout 600
openstack-service restart nova
openstack-service restart ironic
exit

echo "CREATE BAREMETAL FLAVOR"
source ~/stackrc
openstack flavor create --id auto --ram 4096 --disk 40 --vcpus 2 baremetal
openstack flavor set --property "cpu_arch"="x86_64" --property "capabilities:boot_option"="local" baremetal

echo "INTROSPECT OVERCLOUD NODES"
ironic node-list
time openstack baremetal introspection bulk start
ironic node-list

# Identify the IDs of the $deploy_ramdisk and $deploy_kernel from a glance image-list 
# For each ironic node $ironic_id set the deploy_ramdisk and deploy_kernel in addition setting capabilities='boot_option:local'
# e.g. 
# 
# ironic node-update a3488ba4-88d0-4b99-91f0-9dc4c4437508 add properties/capabilities='boot_option:local'
# ironic node-update a3488ba4-88d0-4b99-91f0-9dc4c4437508 add driver_info/deploy_ramdisk='683cef6d-e4e4-445f-a6ca-f29add2356e2'
# ironic node-update a3488ba4-88d0-4b99-91f0-9dc4c4437508 add driver_info/deploy_kernel='679daa33-be63-41b7-b9b8-d765f4f385d4'
# 
# ironic node-update 48449bdd-93d7-4c59-b2e7-3d1b7500b251 add properties/capabilities='boot_option:local'
# ironic node-update 48449bdd-93d7-4c59-b2e7-3d1b7500b251 add driver_info/deploy_ramdisk='683cef6d-e4e4-445f-a6ca-f29add2356e2'
# ironic node-update 48449bdd-93d7-4c59-b2e7-3d1b7500b251 add driver_info/deploy_kernel='679daa33-be63-41b7-b9b8-d765f4f385d4'
# 
# TODO: write shell script to set the above (in a hurry now)

echo "Deploy your overcloud using the following"

echo "time openstack overcloud deploy --templates --ntp-server $NTP --control-scale 3 --compute-scale 2 --neutron-tunnel-types vxlan --neutron-network-type vxlan"
    
    
