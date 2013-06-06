#!/usr/bin/perl

package manage_holds;
use strict;
use Data::Dumper qw(Dumper);
use Exporter; 
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
$VERSION	= 1.00;
@ISA		= qw(Exporter);
@EXPORT_OK	= qw(return_heldjobs check_heldjobs releaseholds );
%EXPORT_TAGS	= ( DEFAULT => [qw(&return_heldjobs)],
		    Both    => [qw(&return_heldjobs &check_heldjobs &releaseholds)]);
sub return_heldjobs{
	my @array;
	my($me) = @_;      ## (gets the value of $me from atc_testMgr)
	open(SQ, "showq |") || die "Failed: $!\n";
	$/ = "\n";
	while(<SQ>) {
		chomp;
		if (( $_ =~ m/$me/ ) && ($_ =~ m/Hold/)){
		push(@array, $_);
		}
	}

	@array = map { my ($jobid, $userid, $state, $pes, $tlimit, $doweek, $month, $day, $timestamp) = split;
	{ 	jobid => $jobid, 
		userid => $userid, 
		state => $state, 
		pes => $pes, 
		tlimit => $tlimit, 
		doweek => $doweek, 
		month => $month, 
		day => $day, 
		timestamp => $timestamp 
	} 
	} @array;
        close(SQ);
	return ( @array ); 
}
sub check_heldjobs{
	my(@array) = @_;
	my @checkjob;
	my @checkjobarray;
	my $hashnos = scalar (@array);
	#print "hashnos are $hashnos\n";
	my $i = 0;
	$/ = "\n";
	my %jobhash;
	while( $i < $hashnos ) {
        	$checkjob[$i] = `checkjob -A $array[$i]{'jobid'}`;
		$i++;
	}
	@checkjobarray = map {my ($name, $state, $uname, $gname, $account, $rclass, $wclimit, $queuetime, $starttime, $tasks, $nodes) = split(/[;]/ );
{
        name => [$name],
        state => [$state],
        uname => [$uname],
        gname => [$gname],
        account => [$account],
        rclass => [$rclass],
        wclimit => [$wclimit],
        queuetime => [$queuetime],
        starttime => [$starttime],
        tasks => [$tasks],
        nodes => [$nodes]} } @checkjob;
my %checkjobarray = @checkjobarray;
#print Dumper \%checkjobarray;
return ( @checkjobarray );
}

sub releaseholds{
	my(@array) = @_;
	my $hashnos = scalar (@array);
	my @wantedstate = ('SystemHold', 'BatchHold');
	my $resvar = system("showres | grep -i preventive") >> 8;  ##changed this to test
	my $i = 0;
	my @releasehold_status;# = 999;
	my @releasedjob_list;
	while ( $i < $hashnos ) {
		if ( $array[$i]{'state'} ~~ @wantedstate ){
			if ( $array[$i]{'state'} eq 'SystemHold' ){
				
				$releasehold_status[$i] = system("releasehold", "-s", "$array[$i]{'jobid'}") >> 8;  ## no or die cause it reports incorrectly
				#print "Error code for releasehold -r is:\t $releasehold_status[$i]:  $array[$i]{'jobid'}\n";
				push @releasedjob_list, $array[$i]{'jobid'}; 
			}
			else {
				$releasehold_status[$i] = system("releasehold", "-b", "$array[$i]{'jobid'}") >> 8;
				#print "Error code for releasehold -b is:\t $releasehold_status[$i]:  $array[$i]{'jobid'}\n";
				push @releasedjob_list, $array[$i]{'jobid'}; 
			}
		}
	$i++;	
	}
	return ( \@releasehold_status, \@releasedjob_list );
	}

1;   ## so that module returns true if loaded ok.

