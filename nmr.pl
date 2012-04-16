#! /usr/bin/perl


my $CVs = 28;
my @avg;

open(COLVAR, $ARGV[0]) || die "$!\n";



my $n = 0;
while ($line = readline(COLVAR)) {
	if ($line =~ /^(#!).*/) {
		next;
	}
	$line =~ s/^\s+//;
	@cur_cv = split(/\s+/, $line);
	for ($i = 0; $i < $CVs; $i++ ) {
		if ($n == 0) {
			$avg[$i] = $cur_cv[$i+1]**(-6);
		} else {
			$avg[$i] += $cur_cv[$i+1] **(-6);
		}	
	}
	$n++;
}

for ($i =0; $i < $CVs; $i++) {
	$x = ($avg[$i]/$n) **(-1/6);
	print "$i\t$x\n";
}
