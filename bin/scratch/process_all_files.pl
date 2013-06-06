#!/usr/bin/perl
#

# Description:
# recursively check for read permission on all files in the given directory
# Author: Craig Idler

use strict;
use File::Find;

$| = 1;

my $name;
my $rs = "";

@ARGV = (".") unless @ARGV;
sub perm {
  if (-R $_ ) {
    print "I can read $_\n";
  } else {
    $rs = "ERRROR: Gazebo does not have read permission on all files in src directory, no copy done\n"; 
    return;
  }
  $name = $File::Find::name;
}
find(\&perm, @ARGV);
print "$rs\n";

exit;
