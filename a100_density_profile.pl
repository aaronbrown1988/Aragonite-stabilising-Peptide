#!/usr/bin/perl
#
# Calculates the Density profile from a number of frames aligned based on the N position
# in the 100 direction. 
#
#
use POSIX;

$step = 0.1;
$range = 60;

opendir(DH, "$ARGV[0]") || die "Couldn't open $ARGV[0]:$!\n";
while ($file = readdir(DH)) {
	if ($file =~ /[0-9]+\.pdb/) {
		push(@files, $file);
	}
}
close(DH);
for ($i = 0; $i < ($range/$step)+1; $i++) {
	$nO[$i] =0;
	$nH[$i] =0;
	$dens[$i] = 0;
}

#for ($i=0; $i < 10; $i++) {
for ($i=0; $i < scalar(@files); $i++) {
	$maxx = -9e99;
	open(FH, "$ARGV[0]/$files[$i]");
	while ($line = readline(FH)) {
		@params = split(/\s+/, $line);
		if ($line =~ /^CRYST.*/) {
			@box = ($params[1],$params[2],$params[3]);
		} elsif ($line !~ /^ATOM/) {
			next;
		}
		if ($params[3] =~ /CHT/) {
			push(@cht,$line);
			if ($params[2] =~ /N/ && $params[6] > $maxx) {
				$maxx = $params[6];
			}
		} elsif ($params[3] =~ /SOL/) {
			push(@sol,$line);
		}
	}
	close(FH);
	$start = 0;
	$n = 0;
	for ($j=0; $j < scalar(@cht); $j++) {
		@params = split(/\s+/, $cht[$j]);
		if (($params[2] =~ /N/) && ($params[6] > ($maxx - 6)) && ($params[6] < ($maxx - 2))) {
			$start += $params[6];
			$n++;
		}
	}
	$start = $start/$n;

	$end = $start+$range;
	print "#Top $files[$i] @ $maxx $start\t $end\t$step\n";
	# Rest bins to Zero.

	for ($j = 0; $j < ($range/$step); $j++) {
		$nO[$j] =0;
		$nH[$j] =0;
	}
	for ($k = 0; $k < scalar(@sol); $k ++) {
		@params = split(/\s+/, $sol[$k]);
		
		if ($params[5] > $end || $params[5] < $start) {
			next;
		}

		$a = $params[5] - $start;
		$b = $a/$step;
		$j = floor($b);
		
		if (($params[3] =~ /SOL/) && ($params[2] =~ /.*OW.*/)) {
			$nO[$j] ++;
		} elsif (($params[3] =~ /SOL/) && ($params[2] =~ /.*HW[12].*/)) {
			$nH[$j]++;
		}
	}

	$vol = ($step)*$box[1] * $box[2];
	$vol *= 0.001;
	for ($j = 0; $j < ($range/$step); $j++ ) {
		$densityA = ($nO[$j] * (18.0/6))/($vol*0.1);
		$density = $nO[$j]*15.9994 + $nH[$j]*1.008;
		$density = ($density*1.66)/$vol;
#		print "#$files[$i]\t $j \t $density\t$densityA \t $nO[$j]\t $nh[$j]\n";
#		$dens[$j] += ($density/10);
		$dens[$j] += $density;
	}
	undef @cht;
	undef @sol;
}
#print "#dist\t dens\n";
for ($i = 0; $i < scalar(@dens); $i++ ) {
#	$dens[$i] /= 1;	
	$dens[$i] /= scalar(@files);	
	
	$x = $i*$step;
	print "$x\t$dens[$i]\n";
}
			

