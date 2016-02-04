#!/bin/bash 
# Filename:                heat_debug.sh
# Description:             Gathers Heat Debug info
# Supported Langauge(s):   GNU Bash 4.2.x and Heat 0.8.0
# Time-stamp:              <2016-02-04 10:30:52 jfulton> 
# -------------------------------------------------------
# Gets heat deployment-show data as described in: 
#  http://hardysteven.blogspot.com/2015/04/debugging-tripleo-heat-templates.html
# 
# Commits horrible string hacks to unpack the embedded error
# into a log file to make debugging a little easier. 
# -------------------------------------------------------
heat resource-list --nested-depth 5 overcloud | grep FAILED | grep " 0 " | awk {'print $4'} > /tmp/failed_heat_zero_ids 
for id in `cat /tmp/failed_heat_zero_ids`; do 
    heat deployment-show $id > /tmp/heat-$id
    echo "Saved a 'heat deployment-show' output to /tmp/heat-$id"
    # very nasty hack...
    py_hack=/tmp/heat-$id.py
    echo "Converting output into Python new line hack: $py_hack"
    echo -n "d = {" > $py_hack
    grep deploy_stdout /tmp/heat-$id  >>  $py_hack
    echo "}" >> $py_hack
    echo "" >> $py_hack
    echo "print d['deploy_stdout']" >> $py_hack
    # ... uggggghhh ....
    python $py_hack | sed -e s/'u001b'//g -e s/'\\/'/g -e s/'\[0m'//g -e s/'\[m'//g  > /tmp/heat-$id.log 
    echo "Try: cat /tmp/heat-$id.log | ccze -A | less -R" 
done 
