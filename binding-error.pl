#!/usr/bin/perl
#
# Here we calculate the error in the adsorption energies.
#
# 

#Work out how many umbrellas we got.
opendir (DH, $ARGV[0]) || die "Couldn't open directory $ARGV[0]: $!\n";
print STDERR "Looking in $ARGV[0] for umbrellas\n";
while ($file = readdir(DH)) {
	if ($file =~ /^[0-9]+/ && (-d $file)) {
		push(@umbrellas, $file);
	}
}

$numbrellas = scalar(@umbrellas);
@umbrellas = sort {$a <=> $b} @umbrellas; 
print STDERR "Found $numbrellas: @umbrellas\n";
closedir(DH);

for ($i = 0; $i < $numbrellas; $i++) {
	opendir(DH, "$ARGV[0]/$umbrellas[$i]");
	$full_found = 0;
	while ($file = readdir(DH)) {
		if ($file =~ /full.xvg/) {
			$full_found=1;
			last;
		}
	}
	if ($full_found == 0 ) {
		print STDERR "Couldn't find full concat. force for umbrella $umbrellas[$i] skipping\n";
		close(DH);
		next;
	}
	closedir(DH);
	open (FH, "$ARGV[0]/$umbrellas[$i]/full.xvg");
	$n= 0;
	$avg=0;
	$avg2=0;
	$nblocks = 0;
	$ba = 0;
	while ($line = readline(FH)) {
		
		if ($line =~ /^[@#;].*/) {
			next;
		}
		$line =~ s/^\s+//;
		@params = split(/\s+/, $line);
		if ($params[0] <500) {next;}
		$ba += $params[1];
		$n++;
		if ($n == 1000) {
			$ba = $ba/$n;
			$avg += $ba;
			$avg2 += $ba * $ba;
			$nblocks++;
			$n = 0;
			$ba = 0;
		}
	}

	# Add in last block	
	$ba = $ba/$n;
	$avg += $ba;
	$avg2 += $ba * $ba;
	$nblocks++;

	$avg2 = $avg2/$nblocks;	

	$avg = $avg/$nblocks;
	$avg = $avg*$avg;

	$var = ($avg2 - $avg)/($nblocks-1);
	push(@vars, $var);
	close(FH);

	$ignore = 0;
	# Now read in the X value and Kb;
	open (FH, "$ARGV[0]/$umbrellas[$i]/umbrella.mdp") || {$ignore = 1};
	$x = 9e99;
	$k = 9e99;
	while ($line = readline(FH) && $ignore != 1) {
		if ($line =~ /pull_init1.*/ ) {
			@params = split(/\s+/, $line);
			$x = $params[2];
		} elsif ($line =~ /pull_k1.*/) {
			@params = split(/\s+/, $line);
			$k = $params[2];
		}
	}
	close(FH);
	if ($x == 9e99 || $k == 9e99) {
		$defaults = 1;
		#die "Failed to find k or X values for umbrella $i\n";
	}
	push(@X, $x);
	push(@K, $k);
	print STDERR "$umbrellas[$i], $x, $k $var\n";


}

for ($j = 4; $j < 12; $j ++) {
	$sum = ($vars[2] + $vars[$j])/4;
	for ($i = 3; $i < $j; $i++) {
		$sum += $vars[$i];
	}
	if ($defaults == 1) {
		$sum = $sum * (0.2)**2;
	} else {
		$sum = $sum * (0.1)**2;
	}
	$error = sqrt ($sum);
	print "2-$j  var: $sum  ";
	print "std dev.: $error\n";
}






