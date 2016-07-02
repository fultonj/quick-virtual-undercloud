#!/usr/bin/env bash
# Filename:                ansible-install.sh
# Description:             Installs Ansible & ceph-ansible
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2016-07-02 15:33:25 jfulton> 
# -------------------------------------------------------
# VARIABLES
RPM_DIR=/tmp/ceph-ansible-rpms/
PLAYBOOKS=/usr/share/ceph-ansible/
URL=http://192.168.122.252/repos/ceph-ansible/
RPMS=(
    ansible-1.9.4-1.el7aos.noarch.rpm
    python-crypto-2.6.1-1.el7aos.x86_64.rpm
    python-ecdsa-0.11-4.el7ost.noarch.rpm
    python-httplib2-0.9.1-2.1.el7ost.noarch.rpm
    python-keyczar-0.71c-2.el7aos.noarch.rpm
    python-paramiko-1.15.2-1.el7aos.noarch.rpm
    sshpass-1.05-5.el7.x86_64.rpm
    ceph-ansible-1.0.4-1.el7.noarch.rpm
)
PKGS=(
    ansible
    ceph-ansible
    python-keyczar
    sshpass
)

# Removing the following pkgs removes OSP dependencies: 
#   python-crypto python-ecdsa python-httplib2 python-paramiko
# Thus, they are not in $PKGS  
# -------------------------------------------------------
# PREPARE 
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the undercloud"; exit 1)

if [ -d "$RPM_DIR" ]; then
    echo "Removing old $RPM_DIR"
    rm -rf $RPM_DIR
fi
echo "Creating new $RPM_DIR"
mkdir $RPM_DIR
# -------------------------------------------------------
# DELETE

echo "Removing Ansible-related packages"
for pkg in ${PKGS[@]}; do
    sudo yum remove $pkg -y; 
done

if [ -d "$PLAYBOOKS" ]; then
    # yum remove should have made this false
    echo "Removing old $PLAYBOOKS"
    sudo rm -rf $PLAYBOOKS
fi
# -------------------------------------------------------
# INSTALL

echo "Downloading RPMs from $URL"
pushd $RPM_DIR
for rpm in ${RPMS[@]}; do
    curl "$URL/$rpm" -O 
done
echo "Installing RPMs from $URL"
sudo yum localinstall *.rpm -y 
popd

echo "Ansible packages installed"
sudo rpm -qa | grep -i ansible

echo "ceph-ansible directory info:"
ls -ld /usr/share/ceph-ansible/ 
# -------------------------------------------------------
# CONFIGURE SSH CLIENT

echo "Configuring ~/.ssh/config to not prompt for non-matching keys and not manage keys via known_hosts"
cat /dev/null > ~/.ssh/config
echo "StrictHostKeyChecking no" >> ~/.ssh/config
echo "UserKnownHostsFile=/dev/null" >> ~/.ssh/config
echo "LogLevel ERROR" >> ~/.ssh/config
chmod 0600 ~/.ssh/config
chmod 0700 ~/.ssh/
