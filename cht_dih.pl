#!/usr/bin/perl
#
# Takes a PDB calculates DIH for direct comaprison with DC
#
use Math::Vector::Real;
use Math::Trig;

open(FH, "$ARGV[0]") || die "Couldn't open: $!\n";
$cr = 0;
while(!eof(FH)) {
@centre = qw(0 0 0);
$n = 0;
#$pos = tell(FH);
while ($line = readline(FH)) {
	if ($line =~ /^CRYST.*/) {
		@params = split(/\s+/, $line);
		$bx = $params[1];
		$by = $params[2];
		$bz = $params[3];
	}
	if ($line !~ /^ATOM.*/) {
		next;
	}
	$line =~ s/CHT [A-Z]/CHT  /;
	@params = split(/\s+/, $line);


	$params[5] = ($params[5] < 0)? $params[5]+$bx: $params[5];
	$params[6] = ($params[6] < 0)? $params[6]+$by: $params[6];
	$params[7] = ($params[7] < 0)? $params[7]+$bz: $params[7];
	$params[5] = ($params[5] > $bx)? $params[5]-$bx: $params[5];
	$params[6] = ($params[6] > $by)? $params[6]-$by: $params[6];
	$params[7] = ($params[7] > $bz)? $params[7]-$bz: $params[7];




	if ($params[2] =~ /.*C[1-5].*/ || $params[2] =~ /.*O5.*/) {
		if ($n!= 0 ) {
			$tx = $centre[0]/$n -$params[5];
			$ty = $centre[1]/$n -$params[6];
			$tz = $centre[2]/$n -$params[7];

			$params[5] = ($tx > $bx/2)? $params[5]-$bx:$params[5];
			$params[6] = ($ty > $by/2)? $params[6]-$by:$params[6];
			$params[7] = ($tz > $bz/2)? $params[7]-$bz:$params[7];
			$params[5] = ($tx < (-$bx/2))? $params[5]+$bx:$params[5];
			$params[6] = ($ty < (-$by/2))? $params[6]+$by:$params[6];
			$params[7] = ($tz < (-$bz/2))? $params[7]+$bz:$params[7];
		}
		$centre[0] += $params[5];
		$centre[1] += $params[6];
		$centre[2] += $params[7];
		$n++;
	}
	if ($params[2] =~ /\bN\b/) {
		@N = ($params[5], $params[6], $params[7]);
	}
	elsif ($params[2] =~ /\bC\b/) {
		@Co = ($params[5], $params[6], $params[7]);
	}
	if ($params[2] =~ /\bO6\b/) {
		@Z = ($params[5], $params[6], $params[7]) ;
	}
	if ($params[2] =~ /\bC6\b/) {
		@Y1 = ($params[5], $params[6], $params[7]) ;
	}
	if ($params[2] =~ /\bCT\b/) {
		@Y2 = ($params[5], $params[6], $params[7]) ;
	}
	if ($params[2] =~ /\bHO6\b/) {
		$cr++;
		last;
	}
}


print "$cr";
$centre[0] /= 6;
$centre[1] /= 6;
$centre[2] /= 6;

#print "N: @N\n";
#print "C: @Co\n";
#print "O6: @Z\n";
#print "C6: @Y1\n";
#print "CT: @Y2\n";

$zV = V(@Z);
$yV = V(@Y1);
$xV = V(@centre);
$nV = V(@N);
$y2V = V(@Y2);
$coV = V(@Co);

# Z - Y - X - N;

$b1 = $yV - $zV;
$b2 = $xV - $yV;
$b3 = $nV - $xV;


$zyxn = dih();
print "\t$zyxn";

#Y-X-N-Co
$b1 = $xV - $yV;
$b2 = $nV - $xV;
$b3 = $coV - $nV;

$yxnc = dih();
print "\t$yxnc";

#Z-Y-N-Co
$b1 = $yV - $zV;
$b2 = $nV - $yV;
$b3 = $coV - $nV;

$zync = dih();

print "\t$zync";

#Z-Y-Co-Y
$b1 = $yV - $zV;
$b2 = $coV - $yV;
$b3 = $y2V - $coV;

$zycy = dih();
print "\t$zycy";

#X-n-c-y
$b1 = $nV - $xV;
$b2 = $coV - $nV;
$b3 = $y2V - $coV;
$xncy = dih();
print "\t$xncy";
print "\n";
#exit;

}



sub dih
{
	check2();
	check();

	$n1 = $b1 x $b2;
	$n2 = $b2 x $b3;

#	$n1 = $n1 *(1/abs($n1));
#	$n2 = $n2 *(1/abs($n1));

#	$dih = rad2deg(acos(($n1*$n2)/(abs($n1)*abs($n2))));


	$arg1 = abs($b2) *$b1 * ($b2 x $b3);
	$arg2 = ($b1 x $b2) * ($b2 x $b3);
	$dih = rad2deg(atan2($arg1, $arg2));
	$dih = ($dih < 0)? 360 + $dih: $dih;
	return($dih);

}


sub check2
{
	$fix=0;
	if ($b1->[0] > ($bx/2)) {
		$b1->[0] -= $bx;
		$fix=1;
	}
	if ($b1->[1] > ($by/2)) {
		$b1->[1] -= $by;
		$fix=1;
	}
	if ($b1->[2] > ($bz/2)) {
		$b1->[2] -= $bz;
		$fix=1;
	}
	if ($b2->[0] > ($bx/2)) {
		$b2->[0] -= $bx;
		$fix=2;
	}
	if ($b2->[1] > ($by/2)) {
		$b2->[1] -= $by;
		$fix=2;
	}
	if ($b2->[2] > ($bz/2)) {
		$b2->[2] -= $bz;
		$fix=2;
	}
	if ($b3->[0] > ($bx/2)) {
		$b3->[0] -= $bx;
		$fix=3;
	}
	if ($b3->[1] > ($by/2)) {
		$b3->[1] -= $by;
		$fix=3;
	}
	if ($b3->[2] > ($bz/2)) {
		$b3->[2] -= $bz;
		$fix=3;
	}
	if ($fix != 0) {
		print STDERR "#fixed $fix  $b1, $b2, $b3\n";
	}
}
sub check
{
	$fix=0;
	if ($b1->[0] < (-$bx/2)) {
		$b1->[0] += $bx;
		$fix=1;
	}
	if ($b1->[1] < (-$by/2)) {
		$b1->[1] += $by;
		$fix=1;
	}
	if ($b1->[2] < (-$bz/2)) {
		$b1->[2] += $bz;
		$fix=1;
	}
	if ($b2->[0] < (-$bx/2)) {
		$b2->[0] += $bx;
		$fix=2;
	}
	if ($b2->[1] < (-$by/2)) {
		$b2->[1] += $by;
		$fix=2;
	}
	if ($b2->[2] < (-$bz/2)) {
		$b2->[2] += $bz;
		$fix=2;
	}
	if ($b3->[0] < (-$bx/2)) {
		$b3->[0] += $bx;
		$fix=3;
	}
	if ($b3->[1] < -($by/2)) {
		$b3->[1] += $by;
		$fix=3;
	}
	if ($b3->[2] < -($bz/2)) {
		$b3->[2] += $bz;
		$fix=3;
	}
	if ($fix != 0) {
		print STDERR "#fixed neg $fix  $b1, $b2, $b3\n";
	}
}
