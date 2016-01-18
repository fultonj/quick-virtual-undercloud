# Filename:                set-ironic-properties.sh
# Description:             Sets missing ironic properties 
# Supported Langauge(s):   bash 4.2.x & openstack 1.0.3
# Time-stamp:              <2016-01-18 16:47:53 jfulton> 
# -------------------------------------------------------
# In OSP8 beta deploying an overcloud without certain properties 
# in ironic resulted in the following error. 
# 
# -----------------------------
# ERROR: rdomanager_oscplugin.v1.overcloud_deploy.DeployOvercloud 
# Configuration has 3 errors, fix them before proceeding. Ignoring 
# these errors is likely to lead to a failed deploy.
# 
# Deployment failed:  Not enough nodes - available: 0, requested: 8
# -----------------------------
# 
# This is a workaround to set these missing properties using the 
# following steps. 
# 
# 1. Identify the IDs of the $deploy_ramdisk and $deploy_kernel from 
#    a glance image-list 
# 
# 2. For each ironic node $ironic_id set the deploy_ramdisk and 
#    deploy_kernel in addition setting capabilities='boot_option:local'
# 
# -------------------------------------------------------
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the undercloud"; exit 1)

echo "Looking for IDs of ramdisk and kernel"

ramdisk_id=$(openstack image list --format=csv | grep ramdisk |  awk 'BEGIN { FS = "," } ; { print $1 }' | sed s/\"//g)
if [ -z $ramdisk_id ]
  then
    echo "Unable to find ramdisk ID with 'openstack image list'. Aborting"
    exit 1
fi

kernel_id=$(openstack image list --format=csv | grep kernel |  awk 'BEGIN { FS = "," } ; { print $1 }' | sed s/\"//g)
if [ -z $kernel_id ]
  then
    echo "Unable to find kernel ID with 'openstack image list'. Aborting"
    exit 1
fi

echo "Using the following ramdisk"
printf "\n";
openstack image show $ramdisk_id
printf "\n";

echo "Using the following kernel"
printf "\n";
openstack image show $kernel_id
printf "\n";

echo "You have the following ironic nodes: "
openstack baremetal list
printf "\n";
echo "This script will set the following for all of the nodes above:"
echo "  - properties/capabilities='boot_option:local'"
echo "  - driver_info/deploy_ramdisk=$ramdisk_id"
echo "  - driver_info/deploy_kernel=$kernel_id"
printf "\n";
read -r -p "Do you want to continue? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]] 
  then
    echo "Here we go...";
else
    echo "Aborting as per your request"
    exit 1
fi

for ironic_id in $(openstack baremetal list  --format=csv | awk 'BEGIN { FS = "," } ; { print $1 }' | grep -v ID | sed s/\"//g); do 
    echo "----- Updating Ironic Node: $ironic_id -----"; 
    printf "\n\n";

    echo "---- <before> ---"
    ironic node-show $ironic_id  | egrep "properties|driver_info" -A 4
    echo "---- </before> ---"
    printf "\n\n";

    echo "setting boot_option..."
    ironic node-update $ironic_id add properties/capabilities='boot_option:local';
    printf "\n\n";

    echo "setting ramdisk..."
    ironic node-update $ironic_id add driver_info/deploy_ramdisk=$ramdisk_id;
    printf "\n\n";

    echo "setting kernel..."
    ironic node-update $ironic_id add driver_info/deploy_kernel=$kernel_id;
    printf "\n\n";

    echo "---- <after> ---"
    ironic node-show $ironic_id  | egrep "properties|driver_info" -A 4
    echo "---- </after> ---"

    printf "\n\n";
done
