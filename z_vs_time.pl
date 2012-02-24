#!/usr/bin/perl

#
# Short script to calulate box dimension against time
#
# Usage z_vs_time.pl dump.xyz [0|1|2]



open(FH, $ARGV[0]);
print "#reading $ARGV[0]\n";
$frame = 0;
$chosen = exists $ARGV[1] ? $ARGV[1] : 2;
while ($line = readline(FH)) {
	$atoms = $line;
	$z_max = -99999;
	$z_min = 99999;
	$line = readline(FH);
	for ($i = 0; $i < $atoms; $i++) {
		$line = readline(FH);
		($type, @coords) = split(/\s+/, $line);
		$z_max = ($coords[$chosen] > $z_max)? $coords[$chosen] : $z_max;
		$z_min = ($coords[$chosen] < $z_min)? $coords[$chosen] : $z_min;
	}
	$z = $z_max - $z_min;
	print "$frame\t$z\t$z_max\t$z_min\n";
	$frame++;
}
		
	
