#!/usr/bin/perl
#
# NMR constraint test.
#
# Takes COLVAR from plumed to calculate distances and NMR constaraints
# outputs the number of satisfied constraints with time.
# Assumes same # of constraints as COLVARS, null constrains specified with -1


open(CV, "$ARGV[0]") || die "couldn't open $ARGV[0] : $!\n";
open(REST, "$ARGV[1]") || die "couldn't open $ARGV[1] : $!\n";
$n = 0;
$nc = 0;
while($line = readline(REST)) {
	$n++;
	push(@const, $line);
	if ($line != -1) {
		$nc ++;
	}
}
close(REST);

while ($line = readline(CV)) {
	if ($line =~ /^#.*/) {
		next;
	}
	$met = 0;
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	for ($i = 0; $i <  $n; $i++) {
		if ($params[$i+1] < $const[$i] && $const!= -1) {
			$met++;
		}
	}
	$norm = $met/$nc;
	print "$params[0]\t$met\t$norm\n";
}
