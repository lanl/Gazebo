#!/usr/bin/perl

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


# This script added to parse specific test failures during an acceptance run. 
# It was created to simplify the data analysis phase. 
#
# Edit away if you can make use of it.

use File::Basename;
use Sys::Hostname;
our $host = hostname;

use Cwd 'abs_path';
$pwd = dirname( abs_path("$0") );
chomp($pwd);
do "$pwd/get_gazebo_config";
my $GH = "$pwd";

our $res_path = $gazebo_conf{"Target_Results_Dir"};     # base directory where everything resides

# ------ got gazebo config values -------------- #

if ( ! -r qq($gazebo_conf{"Target_Results_Dir"}) ) {
    print qq(*** Do not have read permission to results directory $gazebo_conf{"Target_Results_Dir"}, aborting.\n);
    exit -1;
}


#make list error files from the results directory 
@ER_files = split (/\n/, `ls -1 $res_path/*ER`);

# read in each of passed.txt, failed.txt, and unknown.txt
$outfile = "csv_summary_unknown.out";
`rm $outfile`;

open (OUT, ">>$outfile");

@results_files = split / /, "failed.txt unknown.txt";
foreach $results_file (@results_files) {
    $lines = `cat $results_file`;
    @lines = split (/\n/, $lines);
 
    for $line (@lines) {
       
        $end_time = "nada_end_time";
        
        @aaa = split (/\//, $line);
        @aa = split (/_/, $aaa[11]);

        #jobid
        $jobid = $aa[2];  
        $jobid_list .= " $jobid ";
        
        #segment
        $segment = substr($aa[3],0,3);
 
        #test_name
        $test_name = $aa[0];

        #start_time 
        $start_time = substr($aa[2],4,30);

        #end_time
        $end_time_raw = `grep '<end>' $line/*log`; chomp $end_time_raw;
        if ($end_time_raw) {
            $end_time = substr($end_time_raw,6,40);
            chomp $end_time;
        } else {
            $OU_file = `ls -1 $res_path/*OU | grep $jobid`;
            $ER_file = `ls -1 $res_path/*ER | grep $jobid`;
            chomp $OU_file;
            if ($OU_file) {
                $end_time_raw = `grep 'End PBS Epilogue' $OU_file`;
                chomp $end_time_raw;
                if ($end_time_raw) {
                    $end_time = substr($end_time_raw,17,19);
                }
            }
        }

        #result
        @rr = split (/\./, $results_file);
        $result = $rr[0];

        #reason
        $reason="";
        if ($result eq "failed" || $result eq "unknown") {
            #need to find a reason

            $oreason = `cat $jobid.anal`; chomp $oreason;
            if ($oreason) {
                $reason = $oreason;
            } else {
           
                if (`grep "code 1099" $line/$jobid.mn.ER $line/*.log`) { $reason .= "-MOM communication error"; }
                if (`grep "No such file or directory" $line/$jobid.mn.ER $line/*.log`) { $reason .= "-local FS not available"; }
                if (`grep "Device or resource busy" $line/*.ER`) { $reason .= "-nfs resource busy error"; }
                if (`grep "oob-tcp: Communication retries exceeded" $line/$jobid.mn.ER`) { $reason .= "-oob-tcp communication failure"; }
                if (`grep "readv failed: No route to host" $line/$jobid.mn.ER`) { $reason .= "-network communication failure"; }
                if (`ls $line`) { 
                    if (! `ls $line/*log`) {
                        $reason .= "-no_logfile";
                    }
                } else {
                    $reason .= "-no_output_files";
                }
                if (`grep -i "Segmentation" $line/$jobid.mn.ER $line/*.log`) { $reason .= "-segmentation_fault";  }
                if (`grep -i "segfault" $line/$jobid.mn.ER $line/*.log`) { $reason .= "-segmentation_fault";  }
                if (`grep -i "executable available, aborting" $line/$jobid.mn.ER`) { $reason .= "-local FS mount error"; }
                if (`grep -i "cleanly terminate" $line/Otpt.*`) { $reason .= "-residual daemons still running from prior job, mpi timeout error"; }

                if (`grep "VPIC output file miscompare" $line/$jobid.mn.ER $line/*.log`) { $reason .= "-VPIC_miscompare"; }
            }
        }
 
        print OUT "$jobid,$segment,$test_name,$start_time,$end_time,$result,$reason\n";
        }
        
}

foreach $ER_file (@ER_files) {
    chomp $ER_file;
    @jid_path = split (/\//, $ER_file);
    @ER_bits = split (/\./, $jid_path[5]);
    $jid = $ER_bits[0];
    $orphan_jid_list .= " $jid ";
    $reason = "";
    if (`grep "code 1099" $ER_file`) { $reason .= "-MOM_error"; }
    if (! $jid =~ $jobid_list) {
        print OUT "$jid,unknown_segment,unknown_name,unknown_start,unknown_end,unknown_result,$reason\n";
    }
}
close (OUT);
