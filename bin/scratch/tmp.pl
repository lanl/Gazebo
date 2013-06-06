#!/usr/bin/perl


$node_digits = "1,3";
$segname_len = "3";
@cluster_segs = ( "rrz","rrx" );
$tmpcu = "01";
$node_delim = "";
$j = 21;
$k = "";

if ( $node_digits =~ /,/ ) {
   @nada = split ',',$node_digits;
   $k = - $nada[$#nada];
#   $k = "";
} else {
   $k = "0" . "$node_digits";
}
$ks = "$segname_len" . "s";
$kd = "$k" . "d";
$k = sprintf("%$ks%s%$kd",$cluster_segs[$tmpcu],$node_delim,$j);
print "-*-*-*- requested node designation k = $k\n";

exit;
1;
