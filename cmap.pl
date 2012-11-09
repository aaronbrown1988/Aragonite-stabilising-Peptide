#!/usr/bin/perl
#
# Script for scaling the CMAP terms. Currently unused due to 
# GMX 4.5.5 not reading them in or caring about the
# The B states. :(
#

open(CMAP, "$ARGV[0]");
$l = $ARGV[1]/$ARGV[2];
print "scaling by $l\n";
open(NEW, ">$ARGV[0].new");

while ($line = readline(CMAP)) {
	if ($line =~ /^[0-9].*/) {
		$line =~ s/\\//;
		@params = split(/\s+/, $line);
		foreach (@params) {
			$_ = $_*$l;
			print NEW "$_ ";
		}
		print NEW "\\\n"
	} else {
		print NEW "$line";
	}
}
