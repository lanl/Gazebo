#!/usr/bin/perl -w
#
#setup global variables
$| = 1; # disable buffered I/O 
my $prog;
($prog = $0) =~ s/.*\///;

use POSIX;
use strict;
use Sys::Hostname; our $host = hostname;
use IO::Socket;


# run as "user" gazebo 
# so make sure real and effective user id's are gazebo's  
my $id = getpwnam("gazebo");
unless (($< == $id) && ($> == $id)) {
  eval {
    $> = $id;
    $< = $id;
  };
  if ($@) {
   die "$prog: can't make process owner gazebo: $!";
  }
}

print "$prog: running as user id - $>\n";

my $CLI_PORT = 7474;

my $send_flags |= O_NONBLOCK;
my $socket = IO::Socket::INET->new(
	PeerAddr => "yr-fe1.lanl.gov",
	PeerPort => $CLI_PORT,
	Proto => "tcp",
	Type => SOCK_STREAM )
  or die "Couldn't set up socket on port yr-fe1.lanl.gov:$CLI_PORT : $@\n";

my $now = `date`;
print "START - $prog: $now - sending mythd requests on port $CLI_PORT \n"; 
 

#print $socket "id:=1,type:=bogus_again+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
#print $socket "hi there\n";
print $socket "id:=2,type:=PING_req\n";
#print $socket "id:=3,type:=HOST_STATUS_req\n";
#print $socket "id:=5,team:=gzshared,type:=TEST_INFO_req\n";
#print $socket "id:=6,type:=ARCH_INFO_req\n";
#print $socket "id:=7,type:=RUN_TEST_req,test_name:=bogus-test,seg_name:=n14,pe_cnt:=2,time_lim:=01:00\n";
#print $socket "id:=8,type:=RUN_TEST_req,test_name:=test4,seg_name:=bogus_seg,pe_cnt:=2,time_lim:=01:00\n";
#print $socket "id:=9,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=32,time_lim:=02:00\n";
#print $socket "id:=10,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=64,time_lim:=02:00\n";
#print $socket "id:=11,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=96,time_lim:=02:00\n";
#print $socket "id:=12,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=16,time_lim:=02:00\n";
#print $socket "id:=13,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=32,time_lim:=02:00\n";
#print $socket "id:=14,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=64,time_lim:=02:00\n";
#print $socket "id:=15,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=96,time_lim:=02:00\n";
#print $socket "id:=16,type:=RUN_TEST_req,test_name:=iperfV,seg_name:=yra,pe_cnt:=16,time_lim:=00:20\n";
#print $socket "id:=17,type:=RUN_TEST_req,test_name:=iperfV,seg_name:=yra,pe_cnt:=16,time_lim:=02:00\n";
#print $socket "id:=18,type:=RUN_TEST_req,test_name:=test4,team:=gzshared,pe_cnt:=16,seg_name:=yra,time_lim:=00:10\n";
#print $socket "id:=19,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=16,time_lim:=00:10\n";
#print $socket "id:=20,type:=RUN_TEST_req,test_name:=test4,seg_name:=yra,pe_cnt:=16,time_lim:=00:10\n";
#print $socket "id:=20,type:=RUN_TEST_req,test_name:=hplV,team:=gzshared,seg_name:=yra\n";
#print $socket "id:=21,type:=RUN_TEST_req,test_name:=hplV,team:=gzshared,seg_name:=yra,pe_cnt:=120,time_lim:=02:00\n";
#print $socket "id:=31,type:=RUN_TEST_req,test_name:=mpiIO-panfsV,team:=gzshared,seg_name:=yra,pe_cnt:=256,time_lim:=00:40\n";
#print $socket "id:=41,type:=RUN_TEST_req,test_name:=imbV,team:=gzshared,seg_name:=yra,pe_cnt:=128,time_lim:=00:40\n";
#print $socket "id:=52,type:=RUN_TEST_req,test_name:=qcdV,team:=gzshared,seg_name:=yra\n";
#print $socket "id:=53,type:=RUN_TEST_req,test_name:=qcdV,seg_name:=yra,pe_cnt:=512,time_lim:=07:00\n";
#print $socket "id:=54,type:=RUN_TEST_req,test_name:=qcdV-intel,team:=gzshared,seg_name:=cu14,pe_cnt:=128,time_lim:=07:00\n";
#print $socket "id:=64,type:=RUN_TEST_req,test_name:=sweep3dV,team:=gzshared,seg_name:=cu14,pe_cnt:=512,time_lim:=00:40\n";
#print $socket "id:=30,type:=KILL_TEST_req,job_id:=7234a\n";
#print $socket "id:=41,type:=STATUS_req,job_id:=17578\n";
#print $socket "id:=42,type:=STATUS_req,job_id:=17579\n";
print $socket "id:=70,type:=ADD_TEST_req,team:=gzshared,test_name:=newTesty,user:=cwi\n";
#print $socket "id:=70,type:=DELETE_TEST_req,team:=gzshared,test_name:=newTesty,user:=cwi\n";
#print $socket "id:=99,type:=GET_USER_GZGRPS_req,user:=cwi\n";
print $socket "EOF\n";


while  (<$socket>) {
   if (/EOF/ ) {
     print " I got the EOF\n";
     close($socket);
     exit;
   }   
   if ( $_ =~ /EOD/ ) {
     print "$_\n";
   } else {
     print "-> $_\n";
   }
   
}
#   $cli->send("id:=$id, type:=TEST_INFO_res, err_msg:=no seg name present",
#   $cli->send("id:=$id, type:=RUN_TEST_res, err_msg:=no test name present",
