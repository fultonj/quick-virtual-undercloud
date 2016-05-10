echo "CREATE ~/instackenv.json FILE"

jq . << EOF > ~/instackenv.json
{
  "ssh-user": "stack",
  "ssh-key": "$(cat ~/.ssh/id_rsa)",
  "power_manager": "nova.virt.baremetal.virtual_power_driver.VirtualPowerManager",
  "host-ip": "192.168.122.1",
  "arch": "x86_64",
  "nodes": [
    {
      "pm_addr": "192.168.122.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 1p /tmp/nodes.txt)"
      ],
      "cpu": "2",
      "memory": "4096",
      "disk": "40",
      "arch": "x86_64",
      "pm_user": "stack"
    },
    {
      "pm_addr": "192.168.122.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 2p /tmp/nodes.txt)"
      ],
      "cpu": "2",
      "memory": "4096",
      "disk": "40",
      "arch": "x86_64",
      "pm_user": "stack"
    },
    {
      "pm_addr": "192.168.122.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 3p /tmp/nodes.txt)"
      ],
      "cpu": "2",
      "memory": "4096",
      "disk": "40",
      "arch": "x86_64",
      "pm_user": "stack"
    },
    {
      "pm_addr": "192.168.122.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 4p /tmp/nodes.txt)"
      ],
      "cpu": "2",
      "memory": "4096",
      "disk": "40",
      "arch": "x86_64",
      "pm_user": "stack"
    },
    {
      "pm_addr": "192.168.122.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 5p /tmp/nodes.txt)"
      ],
      "cpu": "2",
      "memory": "4096",
      "disk": "40",
      "arch": "x86_64",
      "pm_user": "stack"
    }
  ]
}
EOF

# validate json
curl -O https://raw.githubusercontent.com/rthallisey/clapper/master/instackenv-validator.py
python instackenv-validator.py --file instackenv.json

# install the ssh key and load the env variables to use ironic
ssh-copy-id -i ~/.ssh/id_rsa.pub stack@192.168.122.1
source ~/stackrc

# import the definition of the nodes into ironic
ironic node-list
openstack baremetal import --json instackenv.json
ironic node-list

# if virutal, set up the iPXE hack
echo "Set up daemon for iPXE hack as described in ipxe_workaround.txt"
echo "https://bugzilla.redhat.com/show_bug.cgi?id=1234601#c19"
