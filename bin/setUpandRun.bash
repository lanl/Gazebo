#!/bin/bash 

#  ###################################################################
#
#  Disclaimer and Notice of Copyright 
#  ==================================
#
#  Copyright (c) 2009, Los Alamos National Security, LLC
#  All rights reserved.
#
#  Copyright 2009. Los Alamos National Security, LLC. 
#  This software was produced under U.S. Government contract 
#  DE-AC52-06NA25396 for Los Alamos National Laboratory (LANL), 
#  which is operated by Los Alamos National Security, LLC for 
#  the U.S. Department of Energy. The U.S. Government has rights 
#  to use, reproduce, and distribute this software.  NEITHER 
#  THE GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY, LLC MAKES 
#  ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY 
#  FOR THE USE OF THIS SOFTWARE.  If software is modified to 
#  produce derivative works, such modified software should be 
#  clearly marked, so as not to confuse it with the version 
#  available from LANL.
#
#  Additionally, redistribution and use in source and binary 
#  forms, with or without modification, are permitted provided 
#  that the following conditions are met:
#  -  Redistributions of source code must retain the 
#     above copyright notice, this list of conditions 
#     and the following disclaimer. 
#  -  Redistributions in binary form must reproduce the 
#     above copyright notice, this list of conditions 
#     and the following disclaimer in the documentation 
#     and/or other materials provided with the distribution. 
#  -  Neither the name of Los Alamos National Security, LLC, 
#     Los Alamos National Laboratory, LANL, the U.S. Government, 
#     nor the names of its contributors may be used to endorse 
#     or promote products derived from this software without 
#     specific prior written permission.
#   
#  THIS SOFTWARE IS PROVIDED BY LOS ALAMOS NATIONAL SECURITY, LLC 
#  AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
#  IN NO EVENT SHALL LOS ALAMOS NATIONAL SECURITY, LLC OR CONTRIBUTORS 
#  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
#  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
#  OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
#  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
#  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
#  OF SUCH DAMAGE.
#
#  ###################################################################


#
# Wrapper script necessary to run your Gazebo test.
# Most of this is boiler plate 

source /etc/profile

# set up internationalization 
# set all locale categories to ISO C 

#export LC_ALL C

# note which resource manager is being used at this time so
# we can use the proper env vars below
if [ -z "$GZ_RESOURCEMGR" ]
then
   echo "*** ERROR in $0 - Environment variable GZ_RESOURCEMGR not defined.  Aborting."
   exit
else
  rmgr=$GZ_RESOURCEMGR
  echo "INFO: resource manager defined to be $rmgr"
fi

if [ -z "$GZ_SITE" ]
then
   echo "*** ERROR in $0 - Environment variable GZ_SITE not defined.  Aborting."
   exit
else
  echo "INFO: GZ_SITE defined to be $GZ_SITE"
fi

# load compiler if defined from gzconfig file
if [ ! -z  "$COMPILER" ] 
then
  if [ $GZ_SITE = LLNL ]; then
      use $COMPILER
  elif [ $GZ_SITE = LANL ]; then
      module load $COMPILER
  elif [ $GZ_SITE = SNL ]; then
      module load $COMPILER
  fi
fi


# load mpi library if defined from gzconfig file
if [ ! -z  "$MPILIB" ]
then
  if [ $GZ_SITE = LLNL ]; then
      use $MPILIB
  elif [ $GZ_SITE = LANL ]; then
      module load $MPILIB
  elif [ $GZ_SITE = SNL ]; then
      module load $MPILIB
  fi
fi

# Save the directory in which this test is run, along with the test name.
# This runhome variable should be the directory where the job script is located.
# The default job script is called runit if not redefined in gzconfig.
# 
if [ -z "$GZ_RUNHOME" ]
then
   echo "*** ERROR in $0 - Environment variable GZ_RUNHOME not defined, aborting."
   exit
else
  runhome=$GZ_RUNHOME
  echo "INFO: runhome defined to be $runhome"
fi

if [ -z "$GZ_TESTNAME" ]
then
     testName=${runhome##/*/}
else
     testName=$GZ_TESTNAME 
fi
echo "INFO: testName defined to be $testName"

if [ -z "$GZ_TESTEXEC" ]
then
   echo "*** ERROR, Environmental variable GZ_TESTEXEC not defined, aborting."
   exit
else
   testExec=$GZ_TESTEXEC 
   echo "INFO: testExec defined to be $testExec"
fi

# make sure the executable exists before continuing
if [ -x $GZ_RUNHOME/$GZ_CMD ]
then
   echo "INFO: $GZ_CMD is executable"
else
   echo "ERROR, $GZ_RUNHOME/$GZ_CMD NOT executable, aborting!"
   exit
fi

if [ -z "$GZBIN" ]
then
   echo "*** ERROR in $0 - Environment variable GZBIN not defined.  Aborting."
   exit
else
   echo "INFO: GZBIN is defined to be $GZBIN"
fi

# get list of nodes in use dependent on resource manager being used 
if [ $GZ_RESOURCEMGR = moab-slurm ]; then
   # get job id of this session
  if [ -z "$SLURM_JOBID" ]; then
      echo "*** ERROR in $0 - SLURM ENV variable SLURM_JOBID not defined.  Aborting."
      exit
  else 
     echo "INFO: slurm jobid is $SLURM_JOBID"
     jobid="$SLURM_JOBID"
  fi

  # create a temporary node file simulating PBS_NODES
  nodes=`$GZBIN/checkjob_getNodeList $jobid`
  echo "$nodes" | gawk '{ for ( i=1 ; i <= NF ; i++ ) print $i }' > /tmp/nodefile$$
  MF=/tmp/nodefile$$
  export MF


elif [ $GZ_RESOURCEMGR = moab-torque ]; then


 echo "ugh"

# torque is in use
# The PBS_NODEFILE ENV variable is something the resource manager sets up.
# It contains the list of nodes this job is to run on.
# This is used to determine the "nodes" variable. 
#

#    if [ -z "$PBS_NODEFILE" ]; then
#       echo "*** ERROR in $0 - Environment variable PBS_NODEFILE not defined.  Aborting."
#       exit
#    else
#      echo "INFO: PBS_NODEFILE is $PBS_NODEFILE"
#    fi
 
#    MF=$PBS_NODEFILE
#    export MF
#    nodes=`uniq $PBS_NODEFILE | xargs`
#    echo "INFO: nodes being used are $nodes"

#    if [ -z "$PBS_JOBID" ]; then
#       echo "*** ERROR in $0 - Environment variable PBS_JOBID not defined.  Aborting."
#       exit
#    else
#      jobid=`echo $PBS_JOBID | awk -F. '{print $1}'D`
#      echo "INFO: jobid is $jobid"
#      JOBID=$jobid
#      export JOBID
#      GZ_JOBID=$jobid
#      export GZ_JOBID
#    fi 

fi

if [ -z "$NODES" ]; then
  NODES=$nodes
  export NODES
  GZ_NODES=$nodes
  export GZ_NODES
fi

# npes is the number of processors allocated for this test run.
if [ ! -z $NPES ]; then

  echo "get NPES"

#   if [ $GZ_RESOURCEMGR = moab-slurm ]; then
#      # slurm is in use
#      if [ -z "$SLURM_JOB_NUM_NODES" ]; then
#         echo "*** ERROR in $0 - Environment variable SLURM_JOB_NUM_NODES not defined.  Aborting."
#         exit
#      fi 
#      if [ -z "$SLURM_JOB_CPUS_PER_NODE" ]; then
#         echo "*** ERROR in $0 - Environment variable SLURM_JOB_CPUS_PER_NODE not defined.  Aborting."
#         exit
#      fi 
#      nnodes=$SLURM_JOB_NUM_NODES
#      pes=`echo $SLURM_JOB_CPUS_PER_NODE | awk -F \( '{print $1}'`
#      npes=$nnodes * $pes
#
#   elif [  $GZ_RESOURCEMGR = moab-torque ]; then
#
#         # torque is in use
#         # The "npes" variable can also be derived from the PBS_NODEFILE
#         # where each line represents a new processor.
#         # NPES env variable must be set to actual number of
#         # pe's being used.
#         #
#         npes=`cat $PBS_NODEFILE | wc -l`
#
#
#         if [ -z "$PESPERNODE" ]; then
#            echo "setUpandRun: PESPERNODE environment variable defined, aborting."
#            exit
#         fi 
#         # compute number of processors 
#         npes=`echo "$nodes" | wc -w` 
#         npes=$npes * $PESPERNODE 
#         NPES=$npes
#    fi 
#
#    NPES=$npes
#    export NPES
#
fi
npes=$NPES
echo "INFO: NPES is $npes"


# boiler plate stuff
echo "running $testExec from $runhome"
start=`date --iso-8601=seconds`
echo "-- start time: $start"

# The variable tsid is used to identify the id of the 
# target segment this test should run on. At this point
# this should be running on host 0 of the allocation.
#
hn=`hostname`;
tsId=`$GZBIN/gmsnfromhost $hn`
if [ ! -z $tsId ]
then
  echo "INFO: target segment is $tsId"
else
  echo "*** ERROR in $0 - Can't target segment name.  Aborting."
  exit
fi

# This creates a temporary log directory.
# The actual path to this log directory is arbitrary, but
# the gazebo user needs to be able to read it.

dul="__"
fixedName="$testName$dul$testExec$dul$jobid$dul$tsId"

if [ ! -z $GZ_ATC ]
then
   rm -rf "$runhome/$fixedName.*"
   tmplogdir="$runhome/$fixedName.$start"
else
   rm -rf "${runhome}/gzlogs/${fixedName}.*"
   tmplogdir="${runhome}/gzlogs/${fixedName}.$start"
fi
mkdir -p $tmplogdir
echo "tld -> $tmplogdir"

# create the directory where the final results will go
# a nice place holder in case the job dies
destdir=`$GZBIN/gz_glean -p -g "ATC" -t $testName -f $tmplogdir`
if [[ "$destdir" =~ error ]]
then
  echo "setUpandRun: gz_glean did not create valid destination log directory, exiting"
  exit 1
else
  umask 002
  mkdir -p $destdir
  echo "INFO: output dir: $destdir"
fi

# Do not change the next two lines!
logfile="$tmplogdir/$testName$dul$testExec.log"
echo "logfile ->  $logfile"
LOGFILE=$logfile
export LOGFILE
GZ_LOGFILE=$logfile
export GZ_LOGFILE
touch $logfile

# All the following output is needed for analysis tools.
# Each value is set above or by the resource manager.
# No changes should be made here.
#
touch "$tmplogdir/machine"
echo "$tsId" >> $tmplogdir/machine
echo "<npes> $npes" >> $tmplogdir/machine
echo "<segName> $tsId" > $logfile
echo "<testName> $testName" >> $logfile
echo "<testExec> $testExec" >> $logfile
echo "<npes> $npes" >> $logfile
echo "<JobID> $jobid" >> $logfile
echo "<nodes> $nodes" >> $logfile
echo "<compiler> $COMPILER" >> $logfile
echo "<mpi> $MPILIB" >> $logfile
echo "<params> $TEST_PARAMS" >> $logfile
echo "<rmgr> $rmgr" >> $logfile
echo "<host> $hn" >> $logfile
echo "<user> $USER" >> $logfile

if  [ ! -z $VERSION ]
then
   GZ_VERSION="undef"
   export GZ_VERSION
fi

echo "<vers> $VERSION" >> $logfile
echo "<start> $start" >> $logfile
echo "<dbready>" >> $logfile

# execute the test/job
cd $GZ_RUNHOME

if [ ! -z $SWL ]
then
   $GZBIN/util/mytime $GZ_RUNHOME/$GZ_CMD  2>&1 | tee -a $logfile
else
   $GZBIN/util/mytime $GZ_RUNHOME/$GZ_CMD 2>&1 >> $logfile
fi

# boiler plate stuff
end=`date --iso-8601=seconds`
echo "-- end time: $end"
echo "<end> $end" >> $logfile

touch "$tmplogdir/post_complete"

# make it so that gazebo can read all the data logs
if [ ! -z $GZ_ATC ]
then
   chmod -R 755 ${tmplogdir%/*}
else
   chmod -R 755 $runhome/gzlogs
fi

# do a little cleanup
if [ -e "/tmp/nodefile$$" ]
then
  rm "/tmp/nodefile$$"
fi

# glean the results for later analysis, etc.
if [ ! -z $GZ_ATCGLEAN ]
then
   $GZBIN/gz_glean -g "ATC" -t $testName -f $tmplogdir
  if [ ! -z $GZ_CLEANUP ]
  then
    rm -rf $GZ_ATCGLEAN
  fi 
fi

# save what's appropriate to the gazebo DB.
# The "dbi" file is placed in the result dir to indicate
# that the data has been stored to the DB.
if [ ! -z $GZ_DBINSERT ]
then
  myLogFile=`ls $destdir/*.log`
  if [ -e $myLogFile ]
  then
      myRes=`$GZBIN/mysql/storeresultsDBI -l $myLogFile`
      if [ $myRes = "success"]
      then
        `touch $destdir/dbi`;
      else
        echo "atc_run(setUpandRun): WARNING, database insert failed"
      fi 
  else
    echo "atc_run(setUpandRun): WARNING, no log file data to insert into DB"
  fi 
else
    echo "atc_run(setUpandRun): NOTICE, database insert not performed"
fi

# End of script
exit 1
