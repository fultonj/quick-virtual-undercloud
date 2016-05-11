#!/usr/bin/env bash
# -------------------------------------------------------
# configures undercloud VM with all necessary repos
# -------------------------------------------------------
URL=http://192.168.122.1/repos
RPM_DIR=~/rpms/
ISO_DIR=~/isos/
REPOS=(
    rhel-7-server-rpms 
    rhel-7-server-extras-rpms 
    rhel-7-server-rh-common-rpms
    rhel-7-server-openstack-8-rpms 
    rhel-7-server-openstack-8-director-rpms 
    rhel-7-server-openstack-7.0-rpms 
    rhel-7-server-openstack-7.0-director-rpms 
)
# -------------------------------------------------------
echo "Installing repositories"
dir=/tmp/$(date | md5sum | awk {'print $1'})
mkdir $dir
pushd $dir
for x in ${REPOS[@]}; do
    sudo rm -f /etc/yum.repos.d/$x.repo
    curl $URL/$x/$x.repo -O
    sudo mv -f *.repo /etc/yum.repos.d/
done
popd
rm -rf $dir

echo "The following repository files have been put in place:"
ls -l /etc/yum.repos.d/

echo "The following repositories are active:"
sudo yum repolist
# -------------------------------------------------------
echo "Installing utility packages"
sudo yum install emacs-nox vim wget git screen tree -y 
# -------------------------------------------------------
if [ -d "$RPM_DIR" ]; then
    echo "Removing old $RPM_DIR"
    rm -rf $RPM_DIR
fi
echo "Creating new $RPM_DIR"
mkdir $RPM_DIR
# -------------------------------------------------------
echo "Downloading utils (outside of repos)"
pushd $RPM_DIR
curl -O $URL/utils/all
for x in $(cat all); do curl $URL/utils/$x -O ; done
sudo yum localinstall *.rpm -y 
popd
# -------------------------------------------------------
echo "Downloding Ceph ISO"
if [ -d "$ISO_DIR" ]; then
    echo "Removing old $ISO_DIR"
    rm -rf $ISO_DIR
fi
echo "Creating new $ISO_DIR"
mkdir $ISO_DIR

pushd $ISO_DIR
curl -O $URL/iso/rhceph-1.3.2-rhel-7-x86_64-rh.iso
popd
# -------------------------------------------------------
