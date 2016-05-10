echo "INSTALL THE UNDERCLOUD"
yum install python-rdomanager-oscplugin -y
useradd stack
echo "Redhat01" | passwd stack --stdin
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
su - stack
whoami
cp /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf
echo "edit ~/undercloud.conf"
egrep -v '^#|^$' undercloud.conf
echo "------ does the above look like this? ---------" 
echo "[DEFAULT]"
echo "local_ip = 172.16.0.1/24"
echo "undercloud_public_vip = 172.16.0.10"
echo "undercloud_admin_vip = 172.16.0.11"
echo "local_interface = eth0"
echo "masquerade_network = 172.16.0.0/24"
echo "dhcp_start = 172.16.0.20"
echo "dhcp_end = 172.16.0.120"
echo "network_cidr = 172.16.0.0/24"
echo "network_gateway = 172.16.0.1"
echo "discovery_iprange = 172.16.0.150,172.16.0.180"
echo "[auth]"
echo "------ ------ ------ ------ ------ ------ ------ "
echo "if so you may run ..."
echo "time openstack undercloud install"
