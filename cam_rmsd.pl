#!/usr/bin/perl

#
# Calculate the RMSD from one set of data to another
#

# ARGS source camshifts 

open(SRC, "$ARGV[0]") || die "couldn't open $ARGV[0]\n";

my @orig;
while($line = readline(SRC)) {
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$hn[$params[0]] = $params[1];
	$ha[$params[0]] = $params[2];
}
close(SRC);

opendir(SHIFTS, "$ARGV[1]");
$n =0;
$RMSD1=0;
$RMSD2 =0;
while ($file = readdir(SHIFTS)) {
	if ($file != /.*\.camshift/) {
		next;
	}
	open(SRC, "$ARGV[1]/$file");
	while ($line = readline(SRC)) {
		$line =~ s/^\s+//;
		$diff = $params[2] - $ha[1];
		$diff = $diff **2;
		$RMSD1 += $diff;
		$diff = $params[4] - $hn[1];
		$diff = $diff **2;
		$RMSD2 += $diff;
		$n ++;
	}
	close(SRC);
}
$RMSD1 = sqrt($RMSD1/$n);
$RMSD2 = sqrt($RMSD2/$n);

print "RMSD HA: $RMSD1 HN: $RMSD2";
