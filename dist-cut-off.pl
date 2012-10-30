#!/usr/bin/perl
#
# This script parses the data files produced by charge dist and ring_dist
# Looking for those which are closer than a given cut_off.
#
open(FH, $ARGV[0]) || die "couldn't open $ARGV[0]: $!\n";

while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
	@params = split(/\s+/, $line);
	for ($i = 1; $i < @params; $i++) {
		if ($params[$i] < $ARGV[1]) {
			$print[$i] ++;
		}
	}
}
seek(FH,0,0);
$set = 0;
$old = -1;
while ($line = readline(FH)) {
	if ($line =~ /^[^#@].*/) {
		@params = split(/\s+/, $line);
		print "$params[0]";
		for ($i = 0; $i < @params; $i++) {
			if ($print[$i] > $ARGV[2] ) {
				print ", $params[$i]";
			}
		}
		print "\n";
	} else {
		@params = split(/\s+/, $line);
		$params[1] =~ s/s//;
		if ($print[$params[1]+1] >  $ARGV[2] && $params[2] eq "legend") {
			$params[1] = "s$set";
			print "@params\n";
			print "\@ s$set hidden false\n";
        		print "\@ s$set on\n";
			print "\@ sort s$set  X ascending\n";
			$set ++;

		}
	}
}
