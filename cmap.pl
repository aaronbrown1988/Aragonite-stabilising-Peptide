#!/usr/bin/perl

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
