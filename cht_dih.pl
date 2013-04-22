#!/usr/bin/perl
#
# Takes a PDB calculates DIH for direct comaprison with DC
#
use Math::Vector::Real;
use Math::Trig;

open(FH, "$ARGV[0]") || die "Couldn't open: $!\n";
$pos = 0;
$res = 1;
$chain = 1;
while(!eof(FH)) {
@centre = qw(0 0 0);
$n = 0;
#$pos = tell(FH);
while (!eof(FH)) {
	@params = split(/\s+/, $line);
	if ($params[2] =~ /.*C[1-5].*/ || $params[2] =~ /.*O5.*/) {
		$centre[0] += $params[6];
		$centre[1] += $params[7];
		$centre[2] += $params[8];
		$n++;
	}
	if ($n == 6) {
		$centre[0] /= 6; 
		$centre[1] /= 6; 
		$centre[2] /= 6;
		last;
	}
	$line = readline(FH);
}
seek(FH, $pos, 0);
$res = $params[5];
$chain = $params[4];
while($line = readline(FH)) {
	@params=split(/\s+/,$line);
	if ($line =~/^ATOM.*/ && ($params[5] != $res || $params[4] != $chain)) {
		last;
	}
	if ($params[2] =~ /N/) {
		$nV = V($params[6], $params[7], $params[8]);
	}
	if ($params[2] =~ /O1/) {
		$jV = V($params[6], $params[7], $params[8]);
	}
	if ($params[2] =~ /^C\b/) {
		$cV = V($params[6], $params[7],$params[8]);
	} elsif ($params[2] =~ /.*CT.*/) {
		#print "CT: $params[6] $params[7] $params[8]\n";
		$ctV = V($params[6], $params[7], $params[8]);
	}
	$pos = tell(FH);
}
$rV = V(@centre);
#print "$rV\nN:$nV\nC:$cV\nCT:$ctV\n";
$ua = ($rV - $nV) x ($cV - $nV);
$ub = ($ctV - $cV) x ($nV - $cV);
#print "UA:$ua\nUB:$ub\n";
$cosine = ($ua * $ub)/(abs($ua) *abs($ub));
$dih = 180-rad2deg(acos($cosine));
print "$res\t$dih\n";
}
