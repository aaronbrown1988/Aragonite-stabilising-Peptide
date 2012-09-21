#!/usr/bin/perl

open(XVG, "$ARGV[0]") || die "Couldn't open $ARGV[0]\n";
open(BETA, ">beta.xvg");
open(NBETA, ">non-beta.xvg");

for ($i =2; $i < 30; $i++) {
	$res[$i] = 0;
}
$n = 0;
while ($line = readline(XVG)) {
	if ($line =~ /^[@#]/) {
		print BETA $line;
		print NBETA $line;
		next;
	}
	@params = split(/ +/, $line);
	$beta = ($params[0] < - 110 && $params[1] > 90 );
	$beta = $beta || ($params[0] < -110 && $params[1] < -150);
	$beta = $beta || ($params[0] > 170 && $params[1] > 90);
	$params[2] =~ s/[A-Z]+-//;
	if ($beta == 1) {
	#	print "BETA! $params[2]\n";
		$res[$params[2]]++;
		$n++;
	}
	if ($params[2] =~ /(2|3|6|7|8|9|10|11|13|16|18|20|29)/) {
		print BETA $line;
	} else {
		print NBETA $line;
	}
}

for ($i = 2; $i < 30; $i++) {
	$norm = $res[$i]/$n;
	$cent = $norm*100;
	print "$i\t$res[$i]\t$norm\t$cent\n";
}

