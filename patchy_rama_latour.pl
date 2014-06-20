#!/usr/bin/perl

#
# Patchy Ramachandran plot 
#
#

open (FH, $ARGV[0]) || die "Couldn't open: $ARGV[0]\n";
$c7 =0;
$ar =0;
$al = 0;
$c7ax = 0;

$other = 0;

$ARGV[0] =~ s/.*-//;
$ARGV[0] =~ s/\.xvg//;
$n =0;
while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
	$line =~ s/^\s+//; 
	($x, $y, $type) = split(/\s+/, $line);
	if (in_c7($x,$y)) {
		$c7++;
	}elsif(in_ar($x,$y)) {
		$ar++;
	}elsif (in_al($x,$y)){
		$al++;
	}elsif (in_c7ax($x,$y)) {
		$c7ax++;
	} else {
		$other++;
	}

	$n++;
}

$c7 /= $n;
$ar /= $n;
$al /= $n;
$c7ax /= $n;
$other /= $n;

print "$ARGV[0]\t$c7\t$ar\t$al\t$c7ax\t$other\n";


sub in_c7 {
	local ($x,$y) = @_;
	$ok = 0;
	if ( ($x< 0) && $y > 64) {
		$ok = 1;
	}
	if ( ($x< 0) && $y < -110) {
		$ok = 1;
	}
	if ( ($x> 120) && $y > 64) {
		$ok = 1;
	}
	if ( ($x > 120) && $y < -100 ) {
		$ok = 1;
	}
	return ($ok);
}

sub in_ar {
	local ($x,$y) = @_;
	$ok = 1;
	if ( ($x>0) && $x < 120) {
		$ok = 0;
	}
	if ( ($y < -110) || $y > 64) {
		$ok = 0;
	}
	return ($ok);
}

sub in_al {
	local ($x,$y) = @_;
	$ok = 0;
	if (($x < 120 && $x > 0) && ($y > -60 && $y < 70)) {
		$ok = 1;
	}
	return $ok;
}
sub in_c7ax {
	local ($x,$y) = @_;
	$ok = 1;
	if (($x < 0) || ($x > 120)) {
		$ok = 0;
	}
	if (($y >70) || ($y < -60)) {
		$ok = 0;
	}
	return $ok;
}
