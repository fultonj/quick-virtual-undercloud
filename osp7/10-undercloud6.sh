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

echo "Run set-ironic-properties.sh"

echo "Deploy your overcloud using the following"

echo "time openstack overcloud deploy --templates --ntp-server $NTP --control-scale 3 --compute-scale 2 --neutron-tunnel-types vxlan --neutron-network-type vxlan"
    
    
