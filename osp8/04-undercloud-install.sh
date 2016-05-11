#!/usr/bin/env bash
# -------------------------------------------------------
INSTACK=1
NEW_SSH_KEY=1
INSTALL=1
IMAGES=1
NEUTRON=1
FLAVOR=1
IRONIC=1
HYPERVISOR_IP=192.168.122.1
INSTACKENV=~/instackenv.json
SRC=~/quick-virtual-undercloud/osp8
# -------------------------------------------------------
if [ $INSTACK -eq 1 ]; then 
    # generate an SSH key and install it on dom0
    if [ $NEW_SSH_KEY -eq 1 ]; then 
	echo "Generating and Installing SSH key for stack@$HYPERVISOR_IP (please login just once....)"
	ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
	ssh-copy-id -i ~/.ssh/id_rsa.pub stack@$HYPERVISOR_IP
    fi

    if [[ ! $(ssh stack@$HYPERVISOR_IP "uname -a") ]]; then 
	echo "stack is unable to access $HYPERVISOR_IP. Try NEW_SSH_KEY=1 at top of this script. Exiting."
	exit 1
    fi
    echo -n "Counting installed SSH keys: "
    ssh stack@$HYPERVISOR_IP "wc -l ~/.ssh/authorized_keys"

    # verify we have a list of mac addresses for each overcloud-X VMs's eth0
    if [[ ! -e ~/macs.txt ]]; then
	echo ""
	echo "There is no macs.txt. Make one by running the following on the hypervisor." 
	echo "Then put nodes.txt in stack's homedir. Exiting. "
	echo ""
	echo "   for vm in \$(sudo virsh list --all | grep overcloud | awk '{print \$2};'); do sudo virsh  domiflist  \$vm | grep provisioning | awk '{print \$5};'; done >> macs.txt"
	echo ""
	exit 1;
    fi

    NODE_COUNT=$(wc -l ~/macs.txt | awk {'print $1'})
    NUM=0
    cat /dev/null > $INSTACKENV
    echo "{" >> $INSTACKENV
    echo "  \"ssh-user\": \"stack\"," >> $INSTACKENV
    echo "  \"ssh-key\": \"$(cat ~/.ssh/id_rsa | sed ':a;N;$!ba;s/\n/\\n/g')\"," >> $INSTACKENV
    echo "  \"power_manager\": \"nova.virt.baremetal.virtual_power_driver.VirtualPowerManager\"," >> $INSTACKENV
    echo "  \"host-ip\": \"$HYPERVISOR_IP\"," >> $INSTACKENV
    echo "  \"arch\": \"x86_64\"," >> $INSTACKENV
    echo "  \"nodes\": ["  >> $INSTACKENV
    for mac in $(cat ~/macs.txt); do
	echo "     {" >> $INSTACKENV
	echo "       \"pm_addr\": \"$HYPERVISOR_IP\"," >> $INSTACKENV
	echo "       \"pm_password\": \"$(cat ~/.ssh/id_rsa | sed ':a;N;$!ba;s/\n/\\n/g')\"," >> $INSTACKENV
	echo "       \"pm_type\": \"pxe_ssh\"," >> $INSTACKENV
	echo "       \"mac\": ["  >> $INSTACKENV
	echo "         \"$mac\""  >> $INSTACKENV
	echo "                ], " >> $INSTACKENV
	echo "       \"cpu\": \"2\"," >> $INSTACKENV
	echo "       \"memory\": \"4096\"," >> $INSTACKENV
	echo "       \"disk\": \"40\"," >> $INSTACKENV
	echo "       \"arch\": \"x86_64\"," >> $INSTACKENV
	echo "       \"pm_user\": \"stack\"" >> $INSTACKENV
	NUM=$[$NUM + 1]
	if [[ $NUM -eq $NODE_COUNT ]]; then
	    echo "     }" >> $INSTACKENV
	else
	    echo "     }," >> $INSTACKENV
	fi
    done
    echo "  ] " >> $INSTACKENV
    echo "}" >> $INSTACKENV

    echo ""
    echo "Generated $INSTACKENV. Validating..."
    cp $SRC/helpers/instackenv-validator.py . 
    python instackenv-validator.py --file $INSTACKENV
    echo ""
fi
# -------------------------------------------------------
if [ $INSTALL -eq 1 ]; then 
    echo "INSTALL THE UNDERCLOUD"
    sudo yum install -y python-tripleoclient
    # sudo yum install -y python-rdomanager-oscplugin rhosp-director-images rhosp-director-images-ipa
    cp $SRC/helpers/undercloud.conf ~/undercloud.conf
    echo "verifying hostname is set for undercloud install"
    if sudo hostnamectl --static ; then
	echo "hostnamectl is working"
    else
	# workaround for the following issue:
	#  systemd-hostnamed: Failed to read hostname and machine information: Permission denied
	echo "hostnamectl is not working; trying workaround"
	sudo setenforce 0
	sudo hostnamectl set-hostname undercloud.example.com
	sudo hostnamectl --static
	sudo setenforce 1
	echo "SELinux is enabled"
    fi
    time openstack undercloud install
fi
# -------------------------------------------------------
if [ $IMAGES -eq 1 ]; then 
    source ~/stackrc
    echo "Installing images"
    sudo yum install rhosp-director-images rhosp-director-images-ipa -y 

    echo "Copying images from /usr/share/ to ~/images/"
    mkdir ~/images/
    cp /usr/share/rhosp-director-images/{ironic-python-agent.tar,overcloud-full.tar} ~/images/
    pushd ~/images/
    for tarfile in *.tar; do tar -xf $tarfile; done
    popd

    echo "Uploading Images"
    openstack image list 
    openstack overcloud image upload --image-path /home/stack/images/
    openstack image list 

    echo "You should see PXE files below:"
    ls -l /httpboot 
fi
# -------------------------------------------------------
if [ $NEUTRON -eq 1 ]; then 
    source ~/stackrc
    echo "SET DNS SERVER FOR PROVISIONING NETWORK"
    neutron subnet-list
    sub=`neutron subnet-list -f csv | tail -1 | awk 'BEGIN { FS = "," } ; { print $1 }' | sed s/\"//g`
    neutron subnet-show $sub
    neutron subnet-update $sub --dns-nameserver 8.8.8.8
fi
# -------------------------------------------------------
if [ $FLAVOR -eq 1 ]; then 
    source ~/stackrc
    echo "Listing existing flavors (installed by osp8 now)"
    openstack flavor list

    for flavor in $(openstack flavor list --format=csv | awk 'BEGIN { FS = "," } ; { print $1 }' | grep -v ID | sed s/\"//g); do openstack flavor show $flavor; done
fi
# -------------------------------------------------------
if [ $IRONIC -eq 1 ]; then 
    source ~/stackrc
    echo "Importing nodes from $INSTACKENV into Ironic"
    ironic node-list
    openstack baremetal import --json instackenv.json
    ironic node-list

    echo "Starting bulk introspection"
    date
    time openstack baremetal introspection bulk start
    date 

    # if virutal, set up the iPXE hack
    #echo "Set up daemon for iPXE hack as described in ipxe_workaround.txt"
    #echo "https://bugzilla.redhat.com/show_bug.cgi?id=1234601#c19"

    # -------------------------------------------------------
    # need to fix tagging
    # for ironic_id in $(ironic node-list | awk {'print $2'} | grep -v UUID | egrep -v '^$'); do
    #     ironic node-update $node0 replace properties/capabilities=profile:control,boot_option:local
    #     ironic node-update $node1 replace properties/capabilities=profile:compute,boot_option:local
    # done
    # 
    echo "Ironic node properties are set to the following:"
    for ironic_id in $(ironic node-list | awk {'print $2'} | grep -v UUID | egrep -v '^$'); do 
        echo $ironic_id; 
        ironic node-show $ironic_id  | egrep "memory_mb|profile" ; 
        echo ""; 
    done
    echo "tag each node for each role manually for now"
fi