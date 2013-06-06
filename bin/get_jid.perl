#!/usr/bin/perl
#
# Get jobid of this allocated node
#
# August 2007, Ernie Buenafe

use XML::LibXML;
use Sys::Hostname;

$| = 1;
my $thisnode = hostname;
my $mm = `which mdiag`;
chomp($mm);
my $MDIAG = "$mm -n $thisnode --format=xml";
my $output = `$MDIAG`;
$output =~ s/^\s+//;
$output =~ s/\s+$//;
my $parser = new XML::LibXML();
my $doc = $parser->parse_string($output);
my $root = $doc->getDocumentElement();

foreach my $pbsNode ($root->getChildrenByTagName("node")) {
    my %nodeAttr;

    foreach my $attr ($pbsNode->attributes()) {
	my $name  = $attr->nodeName;
	my $value = $attr->nodeValue;
	$nodeAttr{$name} = $value;
    }

    print "$nodeAttr{JOBLIST}\n";
}
exit;

1;
