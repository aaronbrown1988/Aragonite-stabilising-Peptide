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

opendir(SHIFTS, "$ARGV[1]") || die "couldn't open directory $ARGV[1]\n";
$n =0;
$RMSD1=0;
$RMSD2 =0;
while ($file = readdir(SHIFTS)) {
	if ($file !~ /.*\.camshift/) {
	#	print "skipping $file\n";
		next;

	}
#	print "#using $file\n";
	open(SRC, "$ARGV[1]/$file") || die "couldn't open $ARGV[1]/$file\n" ;
	while ($line = readline(SRC)) {
			if ($line =~ /.*ID.*/) {
				last;
			}
		}
		$line = readline(IN);

	while ($line = readline(SRC)) {
		if (length($line) < 3 ) {
			next;
		}
		$line =~ s/^\s+//;
		@params = split(/\s+/, $line);
		$diff = $params[2] - $ha[$params[0]];
		$diff = $diff **2;
		$RMSD1 += $diff;
		$diff = $params[4] - $hn[$params[0]];
		$diff = $diff **2;
		$RMSD2 += $diff;
		$n ++;
	}
	close(SRC);
}
#print "#$line\n";
closedir(SHIFTS);
#print "#RMSD1: $RMSD1 RMSD2: $RMSD2\n";
$RMSD1 = sqrt($RMSD1/$n);
$RMSD2 = sqrt($RMSD2/$n);

print "RMSD HA: $RMSD1 HN: $RMSD2 calculated over $n shifts\n";
