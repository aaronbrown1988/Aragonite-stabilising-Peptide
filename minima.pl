#!/usr/bin/perl
#
# Written for Zak to calulate the lowest two minima of a free energy surface.
#
open(FH, "$ARGV[0]") || die " Couldn't open $ARGV[0]: $!";



while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/){
		next;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	push(@x, $params[0]);
	push(@y, $params[1]);
}
close(FH);
$points = scalar(@x);
$min = 1e99;
$min_x = 0;
for ($i = 0; $i < $points; $i ++ ) {
	if ($y[$i] < $min ) {
		$min_x = $x[$i];
		$min = $y[$i];
	}
}
print "$min_x\t$min\n";
$min2 = 1e99;
for ($i = 1; $i < ($points-1); $i++ ) {
	if ($y[$i] < $min2 && $y[$i-1] >= $y[$i] && $y[$i+1] > $y[$i] && $y[$i] > $min) {
		$min_x = $x[$i];
		$min2 = $y[$i];
	}
}
print "$min_x\t$min2\n";


