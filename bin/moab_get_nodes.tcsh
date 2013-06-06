#!/bin/tcsh

set runhome = ${RUNHOME}
set here = ${runhome:h}
set here = ${here:h}
set tmpdir = "/tmp/getjid_tmp$$"

# use moab commands to get job id and from that, nodes allocated
if ( $#argv > 0 ) then
   set jobid = $argv[1]
else
   set jobid = `${here}/bin/get_jid`
endif
set cmd = "checkjob $jobid"

#######################
### debugging only ####
#cmd="cat /tmp/tstMe"
#######################

echo '$1 ~ /Allocated/ { getline; array["1"] = $0; getline; array["2"] = $0;  getline; array["3"] = $0; } END { print array["1"] array["2"] array["3"]; }' > ${tmpdir}
set output = `${cmd} | gawk -f ${tmpdir}`
rm -f ${tmpdir}

# print list of nodes allocated to stdout as blank-delimited list
set list = `echo "${output}" | sed 's/^\[//' | sed 's/\]\[/ /g' | sed 's/\]//' | sed 's/:[0-9]*//g'`
echo "${list}"

exit
