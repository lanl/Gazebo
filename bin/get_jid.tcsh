#!/bin/tcsh

# this script prints the job id associated with this running job
# it expects to be run on a back-end node

set thisnode = `hostname`
set mm = `which mdiag`
echo `$mm -n ${thisnode} --format=xml | awk 'BEGIN{FS="\""; RS=" ";}/JOBLIST=/{print $2}'`
exit
