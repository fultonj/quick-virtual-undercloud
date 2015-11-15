echo "SET THE HOSTNAME ON THE UNDERCLOUD"
hostnamectl set-hostname undercloud.redhat.local
systemctl restart network.service
ipaddr=192.168.122.253
echo -e "$ipaddr\t\tundercloud.redhat.local\tundercloud" >> /etc/hosts
yum -y update
reboot
