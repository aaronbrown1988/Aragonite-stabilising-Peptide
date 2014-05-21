#!/usr/bin/perl 

my $bulk = 1.6;
my $baseline = 0;
for ($i= 0; $i < @ARGV; $i++) {
	my @linebuff;
	open(IN, $ARGV[$i]) || die "Couldn't open $ARGV[$i]: $! \n";
	$file = $ARGV[$i];
	$file =~ s/profile.//;
	$file =~ s/\..+//;
	push (@files,$file);
	$avg = 0;
	$n = 0;
	while ($line = readline(IN)) {
		if ($line =~ /^[@#].*/ ) {
			next;
		}

		@params = split(/\s+/, $line);
		if ($params[0] > $bulk) {
			$avg += $params[1];
			$n++;
		}
		push(@linebuff, $line);
	}
	$avg = $avg/$n;
#	if ($baseline == 1e99) {
#		$baseline = $avg;
#		$diff = 0;
#	} else {
		$diff = $avg - $baseline;
#}
	print "@ s$i legend \"$file\"\n";
	print "\@target G0.S$i\n";
	print "\@type xy\n";
	for ($j = 0; $j < @linebuff; $j++ ) {
		@params = split(/\s+/, $linebuff[$j]);
		$params[1] = $params[1] - $diff;
		print "$params[0]\t$params[1]\n";
	}
	@linebuff=undef;

}



