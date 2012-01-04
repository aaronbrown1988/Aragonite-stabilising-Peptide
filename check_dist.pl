#!/usr/bin/perl

open(FH, "chain.lmp");
while ($line = readline(FH)) {
	if ($line  =~ /.*Atoms.*/) {
		last;
}}
readline(FH);

while ($line = readline(FH)) {
	if (length($line) < 3 ) {
		last;
	}
	($a,$b,$c,$d,$e,$f,$g) = split(/\s+/,$line);
	push(@x, $e);
	push(@y, $f);
	push(@z, $g);
#	print "$e, $f,$g\n"
}


$xmin = 9999999;
$xmax = -$xmin;
$ymin = 9999999;
$zmin = 9999999;
$ymax = -$ymin;
$zmax = -$zmin;

for($i=0; $i< 450; $i++) {
	$xmin = ($xmin > $x[$i])? $x[$i] : $xmin;
	$xmax = ($xmax < $x[$i])? $x[$i] : $xmax;
	$ymin = ($ymin > $y[$i])? $y[$i] : $ymin;
	$ymax = ($ymax < $y[$i])? $y[$i] : $ymax;
	$zmin = ($zmin > $z[$i])? $z[$i] : $zmin;
	$zmax = ($zmax < $z[$i])? $z[$i] : $zmax;
}
$xl = 0.5*($xmax - $xmin);
$yl = 0.5*($ymax - $ymin);
$zl = 0.5*($zmax - $zmin);

for($i=0; $i< 450; $i++) {
	for($j=0; $j<450; $j++) {
		$xdist =($x[$i] - $x[$j]);
		$ydist = ($y[$i] - $y[$j]);
		$zdist = ($z[$i] - $z[$j]);	

		$xdist = ($xdist > $xl)? $xdist - $xl: $xdist;
		$ydist = ($ydist > $yl)? $ydist - $yl: $ydist;
		$zdist = ($zdist > $zl)? $zdist - $zl: $zdist;
	
		$dist = sqrt($xdist**2 + $ydist**2 +$zdist**2);

		if ($dist <=0.1 && $i != $j ) {
			printf("$i and $j are too close\n");
}}}

print "Slab bounds:\n";
print  "$xmin -> $xmax\n";
print  "$ymin -> $ymax\n";
print  "$zmin -> $zmax\n";

