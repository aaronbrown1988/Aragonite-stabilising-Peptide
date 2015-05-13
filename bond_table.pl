#!/usr/bin/perl\
#
# Process Bond_data.dat to get unique matched table
#
my @pairs;
my %table;
open(FH, "Bond_data.dat") || die "Couldn't open Bond_data.dat: $!\n";
while($line = readline(FH)) {
	chomp($line);
 	@params = split(/,/,$line);
#undef @pairs;
	for ($i=1; $i < scalar(@params); $i ++) {
		@res = split(/-/, $params[$i]);
		$res[0] =~ s/\:[A-Z0-9]+//;
		$res[1] =~ s/\:[A-Z0-9]+//;
		$found = 0;
#	print "@res\n";
		foreach $test (@pairs) {
			if ($test eq "$res[0]-$res[1]") {
				$found = 1;
				$table{"$res[0]-$res[1]"}++;
			} elsif ($test eq "$res[1]-$res[0]") {
				$found = 1;
				$table{"$res[1]-$res[0]"}++;
			}
		}
		if ($found == 0) {
#	print "#$res[0]-$res[1] not found in @pairs\n";
			push(@pairs,"$res[0]-$res[1]");
			$table{"$res[0]-$res[1]"}++;
		}
	}
}
foreach $key (keys(%table)) {
	print "$key\t$table{$key}\n";
}

