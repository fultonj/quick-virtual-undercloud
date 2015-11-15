echo "DELETING IRONIC RECORDS OF VIRTUAL HARDWARE"

for i in $(ironic node-list | grep -v UUID | awk '{print $2;}'); do ironic node-delete $i; done
rm -f ~/overcloudrc ~/tripleo-overcloud-passwords ~/instackenv.json
