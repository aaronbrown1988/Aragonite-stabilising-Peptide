#!/usr/bin/perl
use POSIX;

#
# Block Averaging 
#
# Usage Data (Col) (Blocks)

open(DATA, "$ARGV[0]") || die "Couldn't open $ARGV[0]: $!\n";
$col = (undef == $ARGV[1])? 1:$ARGV[1];
$blocks = (undef == $ARGV[2])? 100:$ARGV[2];

#Count lines
$lines = 0;
while ($line = readline(DATA)) {
	if ($line =~ /^[#@].*/) {
		next;
	} else {
		$lines ++;
		@params = split(/\s+/, $line);
		push(@points, $params[$col]);
	}
}

close(DATA);

if ( ($lines % $blocks) != 0 ) {
	print STDERR "Last Block will be short :/ \n";
}
$lb = floor($lines/$blocks);
$k = 0;
$avg = 0;
$err = 0;
for ($i = 0; $i < $blocks; $i ++ ) {
	$block = 0.0;
	for ($j = 0; $j < $lb; $j++) {
		if ($k >= $lines ) {
			next;
		}
		$block += $points[$k];
		$k++;
	}
	if ($k >= $lines ) {
		$block /= ($j+1);
		$delta = $block - $avg;
		$avg = $avg + $delta/($i+1);
		#$avg += $block;
		#$err += $block*$block;
		next;
	}
	$block /= $lb;
	$delta = $block - $avg;
	$avg = $avg + $delta/($i+1);
	$avg2 = $avg2 +$delta*($block-$avg);
	#$avg += $block;
	#$err += $block*$block;
}

$avg2 = $avg2 +$delta*($block-$avg);
$var = $avg2/($blocks);
$err = sqrt($var);

#$avg /= $blocks;
#$err /= $blocks;
#$err -= $avg*$avg;
#$err = sqrt($err/($blocks-1));
print "$avg \t$err\n";
