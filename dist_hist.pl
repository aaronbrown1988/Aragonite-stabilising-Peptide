#!/usr/bin/perl
#
# Generates a histogram of how often interactions are < a given cut-off
# usage  dist_hist.pl DAT CUT-OFF
my @hist;
for ($i = 0; $i< 1000; $i++ ){
	$hist[$i] = 0;
}

open(FH, "$ARGV[0]") || die "couldn't open $ARGV[0]: $!\n";
while ($line = readline(FH)) {
	if ($line =~ /^#.*/) {
		next;
	}
	if ($line =~ /^\@.*/) {
		last;
	}
	@params = split(/\s+/, $line);
	for ($i =1; $i < scalar(@params); $i++) {
		if ($params[$i] <= $ARGV[1]) {
			$hist[$i-1] ++;
		}

	}
}
$i=0;
while (!eof(FH)) {
	if ($line =~ /.*legend.*/) {
		@params = split(/\s+/,$line);
#		print "$params[3]\t$hist[$i]\n";
		$pairs{$params[3]} = $hist[$i];
		$i++;
	}
	$line = readline(FH);
}

close(FH);
@out = sort { $pairs{$b} <=> $pairs{$a} } keys %pairs;
for ($i =0; $i < @out; $i++) {
	print "$out[$i]\t$pairs{$out[$i]}\n";
}

