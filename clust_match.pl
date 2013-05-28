#!/usr/bin/perl
#Cluster Matching 
# USAGE DAT

open(DAT, "$ARGV[0]") || die "Couldn't open $ARGV[0]: $!\n";

while (!eof(DAT)) {
	$min = 1e99;
	$min_clust = 1e99;
	$line = readline(DAT);
	if($line =~ /^#.*/ ) {
		next;
	}
	while(length($line)>3) {
		$line =~ s/^\s+//;
		@params = split(/\s+/, $line);
		if ($params[2] < $min) {
			$min = $params[2];
			$min_clust = $params[1];
#			print "New min $min_clust\n";
		}
		$line = readline(DAT);
	}
	print "$params[0]\t$min_clust\t$min\n";
}
