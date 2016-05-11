#!/usr/bin/env bash
# -------------------------------------------------------
# configures undercloud VM with all necessary repos
# -------------------------------------------------------
URL=http://192.168.122.1/repos
RPM_DIR=~/rpms/
ISO_DIR=~/isos/
# -------------------------------------------------------
rhel_repo=$URL/rhel-7-server-rpms/RH7.repo
extras_repo=$URL/rhel-7-server-extras-rpms/RH7-EXTRAS.repo
common_repo=$URL/rhel-7-server-rh-common-rpms/RH7-COMMON.repo
osp_repo=$URL/osp8/core/RH7-RHOS-8.0.repo
dir_repo=$URL/osp8/director/RH7-RHOS-8.0-director.repo
echo "Removing old repositories for OSP and OSP-Director"
sudo rm -f /etc/yum.repos.d/RH7*

echo "Installing repositories for OSP and OSP-Director $1"
dir=/tmp/$(date | md5sum | awk {'print $1'})
mkdir $dir
pushd $dir
for x in $osp_repo $dir_repo $rhel_repo $extras_repo $common_repo; do
    curl $x -O
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
