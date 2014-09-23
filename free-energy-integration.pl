#!/usr/bin/perl
use POSIX;
use Math::BigFloat;

open(FH, $ARGV[0]) || die "Couldn't open $ARGV[0] for reading\n";

$start = $ARGV[1];
$end = $ARGV[2];


$start_i = 0;
$end_i = 1e99;
$kb = 0.0083144621; #kJ/mol/K
#$kb = 0.0019872041; #kCal/mol/K
$kT = $kb * 300 ; 
$beta = 1.0/$kT;
$n = 0;
while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$start_i = (floor($params[0]+0.5) == $start)? $n:$start_i;
	$end_i = (floor($params[0]+0.5) == $end)? $n:$end_i;

	push(@x, $params[0]);
	push(@y, $params[1]);
	$n++;
}

print "C_ads: $x[0]->$start and C_bulk: $start -> $end]\n";


$integral_ads = 0;
for ($i = 0; $x[$i] <= $start; $i++) {
	$dx = abs($x[$i] - $x[$i+1]);
	
	$f_i = exp(-$beta*$y[$i]);
	$f_i1 = exp(-$beta*$y[$i+1]);
	$integral_ads += ($f_i * $dx) + ($f_i1 - $f_i)*$dx*0.5;
}

$integral_ads *= 1/($start-$x[0]);

print "c_ads = $integral_ads\n";
print "sample $i\n";

$integral_bulk = 0;
for (; $x[$i] <= $end; $i++) {
	$dx = abs($x[$i] - $x[$i+1]);
	$f_i = exp(-$y[$i]/$kT);
	$f_i1 = exp(-$y[$i+1]/$kT);
	$integral_bulk += ($f_i * $dx) + ($f_i1 - $f_i)*$dx*0.5;
}

$integral_bulk *= 1/($end - $start);

print "c_bulk = $integral_bulk\n";


$dG = -$kT*log($integral_ads/$integral_bulk);
print "dG = $dG\n";



