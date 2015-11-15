# quick-virtual-undercloud

This repo has my extremely condensed notes for installing [OSP Director](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/7/html/Director_Installation_and_Usage/index.html) in a virtual environment. 

Given a RHEL7 box of sufficient power (32G RAM, 12 CPUs, 50G hard drive) you should be able to follow these steps to quickly have a running undercloud and five overcloud nodes which you can then run `openstack overcloud deploy`. In the end you should have a virtual undercloud and HA overcloud (3 controllers and 2 computes). 

The repo has 10 files to be executed either on the hypervisor or the undercloud VM in a clear order and can mostly be run directly, though the intention is for the user to read and then copy paste as some steps are manual; e.g. donwnload the overcloud images from redhat.com. If you want a fully automated way to do this see [khaleesi](https://github.com/redhat-openstack/khaleesi). If you want to understand what's actually happening please read the [docs](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/7/html/Director_Installation_and_Usage/index.html). I've already read them and these are my unofficial notes to make the process quick for me when I need to stand up an overcloud with whatever variations my customers are interested in. 

```
$ wc -l *.sh
   39 01-hypervisor.sh
    9 02-undercloud.sh
    7 03-hypervisor2.sh
    7 04-undercloud2.sh
   27 05-undercloud3.sh
   17 06-undercloud4.sh
   36 07-hypervisor3.sh
   90 08-undercloud5.sh
   28 09-hypervisor4.sh
   18 10-undercloud6.sh
  278 total
$ 
```
