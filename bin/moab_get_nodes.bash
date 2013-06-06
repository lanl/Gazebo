#!/bin/bash

# list nodes assigned to this run

jobid=" "

# use moab commands to get job id and from that, nodes allocated
set runhome = ${RUNHOME}
set here = ${runhome:h}
set here = ${here:h}

set jobid = `${here}/bin/get_jid`

jobid=`get_jid`
cmd="checkjob $jobid"

#######################
### debugging only ####
#cmd="cat /tmp/tstMe"
#######################

output=`$cmd | gawk '$1 ~ /Allocated/ { getline; array["1"] = $0; getline; array["2"] = $0;  getline; array["3"] = $0; } END { print array["1"] array["2"] array["3"]; }'` 

list=`echo $output | sed 's/^\[//' | sed 's/\]\[/ /g' | sed 's/\]//'`

echo "$list"

exit
