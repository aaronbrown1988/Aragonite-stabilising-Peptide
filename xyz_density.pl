#!/usr/bin/perl
#
# Density Calulator
#
#

use Fcntl qw/:seek/;


#Configuration
$wind_size = 1;
$stride = 0.2;
$zlo = 0;
$zhi = 60.9;
#$act = 9.97e-25; # g/(Angstrom^3)
$act = 9.97e-2; # reduced power


open(DATA, $ARGV[0]);

#Find the last frame
$i=0;
$last=0;
while($line = readline(DATA)) {
	$last = ($line =~ /^3690/)? $i: $last;
	if ($line =~ /^3690/) {
		push(@starts, $i);
	}
	$i++;
}

#Back to the beginning
seek DATA, 0, SEEK_SET;

for ($i = 0; $i <= $last; $i++) {
	$line = readline(DATA);
}

print "#Last frame found at line: $last\n";

$xmax = -9e9;
$xmin = 9e9;
$ymax = $xmax;
$ymin = $xmin;

#Save in the position of the oxygen atoms and use that to calculate the density
while($line = readline(DATA)) {
	chomp($line);
	$line =~ s/^\s+//;
	($type, $i, $j, $k) = split(/\s+/, $line);
	
	if($type >5) {
		last;
	} else {
	
	$xmax = ($i > $xmax) ? $i: $xmax;
	$xmin = ($i < $xmin) ? $i: $xmin;
	$ymax = ($j > $ymax) ? $i: $ymax;
	$ymin = ($j < $ymin) ? $i: $ymin;
	if ($type == 4) {
		push(@x, $i);
		push(@y, $j);
		push(@z, $k);
	}
	
	}
}

$vol = ($xmax - $xmin) * ($ymax - $ymin) * $wind_size;

$x_dist = $xmax - $xmin;
$y_dist = $ymax - $min;
print "#Window dimensions: $x_dist x $y_dist x $wind_size\n";
print "#Volume: $vol A^3\n";

for ($i=$zlo; $i < $zhi; $i += $stride) {
	$n = 0;
	foreach $j (@z) {
		if (($i < $j) && $j < ($i + $wind_size)) {
			$n ++;
		}
	}
	$density =$n / $vol; # Number per A^3
	$n = $n / $vol;
	#$density *= 0.001; # Number per nm^3
	$density *= (18/6); # g/nm^3
	$density = $density / $act; # ratio compared to known bulk
	$mid = $i + 0.5 * $wind_size;
	print "$mid\t$density\t$n\n";
}
