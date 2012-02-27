#!/usr/bin/perl

#
# Patchy Ramachandran plot 
#
#

open (FH, $ARGV[0]) || die "Couldn't open: $ARGV[0]\n";
$r1 = 0;
$r2 = 0;
$r3 = 0;
$other = 0;
while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
	($x, $y, $type) = split(/\s+/, $line);
	if (in_r1($x,$y)) {
		$r1++;
	} elsif (in_r2 ($x,$y)) {
		$r2++;
	} elsif (in_r3($x,$y)) {
		$r3++;
	} else {
		$other ++;
	}
}

print "$r1\t$r2\t$r3\t$other\n";

sub in_r1 {
	local ($x,$y) = @_;
	$ret = 1;
	if ($x  > -130) { $ret = 0; }
	if ($y > -140 && $y < 100) { $ret = 0; }
	return $ret;
}

sub in_r2 {
	local ($x,$y) = @_;
	$ret = 1;
	if ($x > -130 ) { $ret = 0;}
	if ($y >50 || $y < -68) { $ret = 0; }
	return $ret;
}

sub in_r3 {
	local ($x,$y) = @_;
	$ret = 1;
	if ($x < 36) {$ret = 0;}
	if ($x > 115) {$ret = 0;}
	if ($y < 11) { $ret = 0;}
	if ($y > 78) { $ret = 0;}
	return $ret;
} 
	
