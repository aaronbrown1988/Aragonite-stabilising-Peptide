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
	($times, $x, $y) = split(/\s+/, $line);
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
	if (($times %5) == 1) {
		$total[0] += $c7;
		$total[1] += $ar;
		$total[2] += $al;
		$total[3] += $c7ax;
		$total[4] += $other;
		$total[5] += $n;
		$c7 /= $n;
		$ar /= $n;
		$al /= $n;
		$c7ax /= $n;
		$other /= $n;
		$times*= 1.7*2/1000;
		print "$times\t$c7\t$ar\t$al\t$c7ax\t$other\n";
		$c7 *= $n;
		$ar *= $n;
		$al *= $n;
		$c7ax *= $n;
		$other *= $n;
		#$n = 0;
	}



}


print <<END;
@ s0 legend "C7"
@ s1 legend "\\f{Symbol}a\\f{}\\sr"
@ s2 legend "\\f{Symbol}a\\f{}\\sl"
@ s3 legend "C7\\sax"
@ s4 legend "Other"
@ s0 on
@ s0 hidden false
@ s1 on
@ s1 hidden false
@ s2 on
@ s2 hidden false
@ s3 on
@ s3 hidden false
@ s4 on
@ s4 hidden false
END


$total[0] /= $total[5];
$total[1] /= $total[5];
$total[2] /= $total[5];
$total[3] /= $total[5];
$total[4] /= $total[5];
print "# $total[0]\t$total[1]\t$total[2]\t$total[3]\t$total[4]\n";

$kt = 0.593;

$ar = $kt*log($total[0]/$total[1]);
$al = ($total[2] > 0)? $kt*log($total[0]/$total[2]): 0;
$c7ax = ($total[4] > 0)? $kt*log($total[0]/$total[4]):0;

print "# c7 $c7 ar $ar al $al c7ax $c7ax \n";

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
	if (($y <70) && ($y > -60)) {
		$ok = 0;
	}
	return $ok;
}
