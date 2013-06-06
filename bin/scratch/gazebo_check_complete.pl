#!/usr/bin/perl

our (%opts,%TestCoverage,%RunTime);
our $run_time_symbol    = "real ";
our $node_symbol      = "running on nodes -> ";
our $pbs_symbol      = "^Nodes:\t+";
our $pct;
our $pctDone = 0.0;
our $missing_info = "";
our $ct;
our ($test,$line,@lines,$logfile,$node,$nodelist,@nodes,$i,$j,$k,$e,$c,$jj,$s,$mm,$go,
     @tests,$path,$ndone,$ls,@logs,$n,%TestTime,%CUTime);
our $no_nodes_list_found = 0;
my ($nad,$log,$now,$logcontents,$logcountp,$logcountf);
$now = `date "+%m-%d_%H:%M"`;
chomp($now);
our $dir = "/opt/nfz/HPC/test_results";
our $pwd = `pwd`;
chomp($pwd);
our $output = "$pwd/coverageReport.$now";


our @cus = (	"01",
		"02",
		"03",
		"04",
		"05",
		"06",
		"07",
		"08",
		"09",
		"10",
		"11",
		"12",
		"13",
		"14"
           );
our @qcus = (
                @cus,
		"01-03-05-07",
		"09-11-12-13"
           );

use Getopt::Std;

$opts{D} = "";
$opts{d} = "";
$opts{T} = "";
getopts("d:T:S:E:hxctNX",\%opts);

$me = "$0";
# -x option is just to change the name in the help msg for when called by rr_generate_coverage_report
if ( $opts{x} ) { $me = "rr_generate_coverage_report"; }

if ( $opts{h} ) {
 $i = <<EOF;
Usage:  $me [-h]|[ -c | -t ] [-T <list of test names>] [ -d <full path of logs directory desired> ] [ -S <day>] [ -E <day>] [-N]
          where -h gives this message
                -c generates coverage report (minutes/node of passed tests)
                -t generates workload mix report along with test coverage (which tests/node)
                -T allows you to limit the coverage report to a specific comma-separated list of tests
                -d allows use of an alternate directory; the default is: 
                 /opt/nfz/HPC/test_results/test_data_yellow
                -S allows the specification of day to start analysis; the default is 15 days before end date
                   where <day> is one of the std date strings like "3 days ago" or "yesterday"
                -E allows the specification of day to end analysis; the default is today
                   where <day> is one of the std date strings like "3 days ago" or "yesterday"
                -N also lists which logs have no PASS/FAIL indication and/or no node list

EOF
   print "$i\n";
   exit;
}

if ( $opts{t} ) {	# -t implies -c
   $opts{c} = 1;
}

if ( "$opts{T}" ne "" ) {		# user has specified specific list of tests to summarize
   @tests = split ',',$opts{T};
}

if ( "$opts{E}" ne "" ) {
   $end = `date -I -d "$opts{E}"`;
   chomp($end);
} else {
   $end = `date -I`;
   chomp($end);
}

if ( "$opts{S}" ne "" ) {
   $start = `date -I -d "$opts{S}"`;
   chomp($start);
} else {
   $start = `date -I -d "15 days ago $end"`;
   chomp($start);
}

print "Analyzing tests from $start to $end ...\n";

 

$dd = "";		# set up to use directory specified by user if present
if ( "$opts{d}" ne "" ) { 
   $dir = "$opts{d}";
   chomp($dir);
   $dd  = "-d $dir";
}

if ( "$opts{T}" ne "" ) {
   print "Checking $dir for test(s) $opts{T} ...\n";
} else {
   if ( "$opts{d}" ne "" ) { 
      print "Checking $dir ...\n";
   } else {
      print "Checking test_results directory ...\n";
   }
}

$ls = `/opt/nfz/HPC/RR_staging_area/bin/find_test_dirs -s $start -e $end $dd`;
@logs = split '\n',$ls;
$n = @logs;
$ndone = 0;

$mm = 0;
$s = 0;
$e = 0;
$i = 0;
$j = 0;
$jj = 0;
print "Number of logs = $n\n";
A:
foreach $path ( @logs ) {

   next A if (! -e "$path" );
   next A if (! -d "$path" );
   next A if ( -l "$path" );
   $ndone++;
   $pctDone = sprintf("%3.0f",(($ndone/$n)*100));       # calculate % complete
   print "$pctDone\%\010\010\010\010";			# let user know how far we are now

   $log = "$path";
   $log =~ s/.*\///;
   if ( $log =~ /qcd/ ) {	# -------- qcd jobs --------------
           next A if (! -e "$path/post_complete" );
           $logcountp = `tail $path/qcd.log | grep 'PASS.*golden image' | wc -l`;
           $logcountf = `tail $path/qcd.log | grep 'FAIL.*golden image' | wc -l`;
           if ( $opts{N} ) {
              $go = `cat $path/qcd.log | grep '$node_symbol'`;
              if ( "$go" eq "" ) {
	         @nodes = <$path/*.mc.OU>;
	         if ( $#nodes >= 0 ) {
	            $z = $nodes[0];
                    if ( -e "$z" ) {
                       $logfile	= `cat $z`;
                       @lines 	= split '\n',$logfile;
                       foreach $line ( @lines ) {
                          if ( $line =~ /$pbs_symbol/ ) {
                             $go = "foundit";
                          }
                       }
                    }
                 }
              }
              if (( "$go" eq "" ) || (( $logcountp == 0 ) && ( $logcountf == 0 ))) {
		 $missing_info .= "$qlog ";
              }
           }
           $go = 0;
           if (( $logcountp == 3 ) && ( $logcountf == 0 )) {
              $go = 1;
	      $mm++;
           }
           ($m,$kk,$jjj) = split '_',$log;
           ($m,$kk) = split '\.',$jjj;
           collect_stats("$log","$path","$m");

   } else {			# -------- all other jobs --------------

      next A if (! -e "$path/post_complete" );

      $tmp = `cat $path/*.log`;
      if ( $tmp =~ /PASS/ ) {
         $logcountp = 1;
      } else {
         $logcountp = 0;
      }
      if ( $tmp =~ /FAIL/ ) {
         $logcountf = 1;
      } else {
         $logcountf = 0;
      }
      if ( $tmp =~ /DIFF/ ) {
         $logcountf += 1;
      }
      if ( $opts{N} ) {
         $go = `cat $path/*.log | grep '$node_symbol'`;
         if ( "$go" eq "" ) {
	    @nodes = <$path/*.mc.OU>;
	    if ( $#nodes >= 0 ) {
	       $z = $nodes[0];
               if ( -e "$z" ) {
                  $logfile	= `cat $z`;
                  @lines 	= split '\n',$logfile;
                  foreach $line ( @lines ) {
                     if ( $line =~ /$pbs_symbol/ ) {
                        $go = "foundit";
                     }
                  }
               }
            }
         }
         if (( "$go" eq "" ) || (( $logcountp == 0 ) && ( $logcountf == 0 ))) {
	     $missing_info .= "$log ";
         }
      }
      $go = 0;
      if (( $logcountp > 0 ) && ( $logcountf == 0 )) {
         $go = 1;
	 $mm++;
      }
      ($m,$kk,$jjj) = split '_',$log;
      ($m,$kk) = split '\.',$jjj;	# get cu into $m
      collect_stats("$log","$path","$m");
   }
}

$m = $n - $i;
$jjj= $n - $j;

print " ----------------------------------------- \n";
print "---- Summary of $dir as of $now ----\n\n";
print "Number of completed jobs = $i, number of incomplete jobs = $m\n";
print "Number of completed and PASSED jobs = $mm\n";
print "Number of jobs with .mc.OU = $j, number of jobs with .mc.ER = $jj\n";
print "Number of jobs missing .mc.OU = $jjj\n";
print "Number of empty directories = $e\n";
if ( $opts{c} ) {
   print "Number of jobs included in coverage report = $s\n";
   print "Number of jobs with no nodes list in log file = $no_nodes_list_found\n";
   print "Coverage report is in $output\n";
}
if ( $opts{N} ) {
   print " ----------------------------------------- \n";
   @nada = split ' ',$missing_info;
   $n = @nada;
   $missing_info = "";
   foreach $nad ( sort {$a cmp $b} @nada ) {
      $missing_info .= "$nad\n";
   }
   print " The following $n test(s) have no PASS/FAIL indication, and/or have no node list:\n$missing_info\n";
}
print " ----------------------------------------- \n";

if ( $opts{c} ) {
   open (OUT,">$output");
   print OUT " ----------------------------------------- \n";
   print OUT "Summary of $dir as of $now:\n";
   print OUT "Number of completed jobs = $i, number of incomplete jobs = $m\n";
   print OUT "Number of completed and PASSED jobs = $mm\n";
   print OUT "Number of jobs with .mc.OU = $j, number of jobs with .mc.ER = $jj\n";
   print OUT "Number of jobs missing .mc.OU = $jjj\n";
   print OUT "Number of empty directories = $e\n";
   print OUT "Number of jobs included in coverage report = $s\n";
   print OUT "Number of jobs with no nodes list in log file = $no_nodes_list_found\n";
   print OUT " ----------------------------------------- \n";
   if ( $opts{N} ) {
      @nada = split ' ',$missing_info;
      $n = @nada;
      $missing_info = "";
      foreach $nad ( sort {$a cmp $b} @nada ) {
         $missing_info .= "$nad\n";
      }
      print OUT " The following $n test(s) have no PASS/FAIL indication, and/or have no node list:\n$missing_info\n";
      print OUT " ----------------------------------------- \n";
   }
   coverage_report();
   print OUT "\n$report\n";
   print OUT " ----------------------------------------- \n";
   close(OUT);
}
exit;

### ---------------------------------------------------------- ###

sub collect_stats {
   my $log = "$_[0]";
   my $dir = "$_[1]";
   my $cu = "$_[2]";

   $ls = `ls -m $dir`;
   chomp($ls);
   if ( "$ls" eq "" ) {		# number of empty directories
      $e++;
   }
   if ( $ls =~ /.mc.ER/ ) {	# number of moab stderr files
      $jj++;
   }
   if ( $ls =~ /.mc.OU/ ) {	# number of moab stdout files
      $j++;
   }
   if ( $ls =~ /post/ ) {	# number of completed jobs
      $i++;
   }

   # compile coverage report if requested
   if ( $opts{c} && $go ) {
      collect_coverage("$log","$dir","$cu");
      $s++;
   }
}

### ---------------------------------------------------------- ###

sub collect_coverage {
      my ($z);
      my $log = "$_[0]";
      my $dir = "$_[1]";
      my $cu = "$_[2]";

      @nada	= split '_',$log;
      $test	= "$nada[0]";

      # foreach test, read the log file to get node list and run time
      if ( -e "$dir/$test.log" ) {
         $logfile	= `cat $dir/$test.log`;
         @lines 	= split '\n',$logfile;
	 @nodes		= ();
         foreach $line ( @lines ) {
            if ( $line =~ /$node_symbol/ ) {
               $nodelist = "$line";
               $nodelist =~ s/$node_symbol//;
               @nodes = split ' ',$nodelist;
            }
            if ( $line =~ /$run_time_symbol/ ) {
               $runtime = "$line";
               $runtime =~ s/$run_time_symbol//;
               $runtime = ( $runtime / 60.0 );
            }
         }

         # Handle empty nodelist via .mc.OU file (PBS Epilogue)
         if ( $#nodes < 0 ) {
	    @nodes = <$dir/*.mc.OU>;		# borrow @nodes to hold filenames
	    if ( $#nodes >= 0 ) {
	       $z = $nodes[0];
               @nodes = ();			# return @nodes
               if ( -e "$z" ) {
                  $logfile	= `cat $z`;
                  @lines 	= split '\n',$logfile;
	          $z = 0;
                  foreach $line ( @lines ) {
                     if ( $line =~ /$pbs_symbol/ ) {
                        $nodelist = "$line";
                        $nodelist =~ s/$pbs_symbol//;
		        $z = 1;
                     } else {
		        if ( $z == 1 ) {
			   if ( $line =~ /^n[0-9][0-9]-[0-9][0-9][0-9]/ ) {
			      $nodelist .= " $line";
		           } else {
			      $z = 2;
			      last;
			   }
		       }
		    }
                  }
                  @nodes = split ' ',$nodelist;
               }
	    }
	 }

         if ( $#nodes < 0 ) { 
#	    print "No nodes found for run $log -- ignoring\n";
            $no_nodes_list_found++;
	    $node_minutes = 0;
	 } else {
	    $node_minutes = $runtime * ($#nodes + 1);
	 }
	 
         # total time spent for this cu
         if ( defined $CUTime{$cu} ) {
            $CUTime{$cu} += $node_minutes;
         } else {
            $CUTime{$cu} = $node_minutes;
         }

         if ( "$opts{T}" ne "" ) {		# user has specified specific list of tests to summarize
            if ($opts{T} =~ /$test/ ) {
               # total time spent for this test on this cu
               $z = sprintf("%s+%s.%d",$cu,$test,8*($#nodes+1));
               if ( defined $TestTime{$z} ) {
                  $TestTime{$z} += $node_minutes;
               } else {
                  $TestTime{$z} = $node_minutes;
               }
            }

         } else {

            # total time spent for this test on this cu
            $z = sprintf("%s+%s.%d",$cu,$test,8*($#nodes+1));
            if ( defined $TestTime{$z} ) {
               $TestTime{$z} += $node_minutes;
            } else {
               $TestTime{$z} = $node_minutes;
            }
         } 


         # track time executed on each node for each test
         foreach $node ( @nodes ) {
            if ( "$opts{T}" ne "" ) {		# user has specified specific list of tests to summarize
               if ($opts{T} =~ /$test/ ) {
                  # specific time spent for this test on this node
                  $z = sprintf("%s+%s.%d",$node,$test,8*($#nodes+1));
                  if ( defined $TestCoverage{$z} ) {
                     $TestCoverage{$z} += $runtime;
                  } else {
                     $TestCoverage{$z} = $runtime;
                  }
               }

            } else {

               # specific time spent for this test on this node
               $z = sprintf("%s+%s.%d",$node,$test,8*($#nodes+1));
               if ( defined $TestCoverage{$z} ) {
                  $TestCoverage{$z} += $runtime;
               } else {
                  $TestCoverage{$z} = $runtime;
               }
            }

            # total time spent on this node
            if ( defined $RunTime{$node} ) {
               $RunTime{$node} += $runtime;
            } else {
               $RunTime{$node} = $runtime;
            }
         }
      }
}

sub coverage_report {
      my $y = "";
      my (@cts, @ts, @tt, %hash, $nt, $ct, $m
         );

      $report = "\nAnalyzing tests from $start to $end ...\n";

      @cts = sort {$a cmp $b} keys %TestTime;	# cu+test keys
      @ts = ();
      foreach $t ( @cts ) {			# all test names, repeated
         @tt = split '\+',$t;
	 push(@ts,$tt[1]);
      }
      undef %hash;
      @hash{@ts} = ();
      @ts = sort {$a cmp $b} keys %hash;	# finally, sorted and unique list of test names

      if ( "$opts{T}" ne "" ) {		# user has specified specific list of tests to summarize
         $report .= "\nThis Coverage Report Includes the Following Tests Only:\n\t@tests\n\n";
      } else {
	 @tests = @ts;			# else report on all found tests
         $report .= "\nThis Coverage Report Found the Following Tests:\n\t@tests\n\n";
      }



      # Display per CU coverage
      $report .= "\nCU Coverage by Node_Minutes\n===========================\n";
      foreach $xcu ( @qcus ) {
         $cu = "cu$xcu";
         $report .= "\nCU $xcu % by test:\n";
         foreach $ct ( @cts ) {
	    next if ( not $ct =~ /^$cu\+/ );
            if ( $TestTime{$ct} > 0 ) {
	       $pct = $TestTime{$ct} / $CUTime{$cu} * 100.0;
               $test = $ct;
               $test =~ s/^$cu\+//;
	       $report .= sprintf("%20s : %8d / %8d = %7.2f\%\n",$test,$TestTime{$ct},$CUTime{$cu},$pct);
	    }
         }
      }

      # now format a report of node coverage
      $y = "";
      if ( "$opts{T}" ne "" ) {		# user has specified specific list of tests to summarize
         $y = " for @tests only";
      }
      foreach $cu ( sort {$a cmp $b} @cus ) {
      $report .= "\n\n\nCU $cu Node Coverage in Minutes$y: \n\n\t000: ";
         $m = 0;
         $firstrow = 1;
         for ( $z=0; $z<144; $z++,$m++ ) {
             $node = sprintf("n%s-%03d",$cu,$z);
             if ( "$opts{T}" ne "" ) {		# user has specified specific list of tests to summarize
                my $x = 0;
                foreach $test ( @tests ) {
                   if ($opts{T} =~ /$test/ ) {
                      $ct = sprintf("%s+%s",$node,$test);
                      $x += $TestCoverage{$ct};
                   }
                }
                $report .= sprintf("%6d ",$x);
             } else {
                $report .= sprintf("%6d ",$RunTime{$node});
             }
             if ( $firstrow ) {
               if ( ($z > 0) && ($m%9 == 0) ) {
                  $report .= "\n\t";
                  $report .= sprintf("%03d: ",$z+1);
                  $firstrow = $m = 0;
               }
             } else {
               if ( ($z > 0) && ($m%10 == 0) ) {
                  $report .= "\n\t";
                  $report .= sprintf("%03d: ",$z+1);
               }
             }
         }
      }

      if ( $opts{t} ) {
         foreach $cu ( sort {$a cmp $b} @cus ) {
          $report .= "\n\n\n---------------------  Workload Mix % by Test and Node for CU $cu ---------------------";
          foreach $testName ( @tests ) {
	    $test = "cu$cu+$testName";
	    # Determine if any nodes in the CU ran this test
            $covered = 0;
            for ( $z=0; $z<144; $z++,$m++ ) {
                $node = sprintf("n%s-%03d",$cu,$z);
                $nt = sprintf("n%s-%03d+%s",$cu,$z,$testName);
		if ( $TestCoverage{$nt}  > 0.0 ) {
                   $covered = 1;
		   last;
		}
	    }

            if ( $covered ) {
                $report .= "\n\ncu$cu $testName:\n\t000: ";
                $m = 0;
                $firstrow = 1;
                for ( $z=0; $z<144; $z++,$m++ ) {
                    # calculate percent spent for this test on this node
                    $node = sprintf("n%s-%03d",$cu,$z);
                    $nt = sprintf("n%s-%03d+%s",$cu,$z,$testName);
		    if ( $RunTime{$node} > 0.0 ) {
                       $pct = ( $TestCoverage{$nt} / $RunTime{$node} ) * 100.0;
		    } else {
		       $pct = 0.0;
		    }
                    $report .= sprintf("%5.1f\%  ",$pct);
                    if ( $firstrow ) {
                      if ( ($z > 0) && ($m%9 == 0) ) {
                         $report .= "\n\t";
                         $report .= sprintf("%03d: ",$z+1);
                         $firstrow = $m = 0;
                      }
                    } else {
                      if ( ($z > 0) && ($m%10 == 0) ) {
                         $report .= "\n\t";
                         $report .= sprintf("%03d: ",$z+1);
                      }
                    }
                }
            }
          }
         }
      }
}

### ---------------------------------------------------------- ###


1;
