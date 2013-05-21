#!/usr/bin/perl
#
# Glue discontinuous replica_temp trajectories back together
# CAVEAT: The two can't overlap! I cba to check for that.
# USAGE: Replicas <N bits>

$rep = $ARGV[0];
print "0\t";
for ($i = 0; $i < $rep; $i++) {
	$last[$i] = $i;
	print "$i\t";
}
print "\n";
$j = 0;
$n = 0;
for ($i = 1; $i < scalar(@ARGV); $i++) {
	open(DAT, $ARGV[$i]) || die "Couldn't open $ARGV[$i]: $!\n";
	$line = readline(DAT); 
	@params = split(/\s+/, $line);
	if ($params[0] == 0) {
		for ($j = 1; $j < scalar(@params); $j++) {
			$lut[$params[$j]] = $last[$j-1];
			print "# $j = $lut[$j-1] \n";
		}
	}
	while($line = readline(DAT)) {
		@params = split(/\s+/, $line);
		for ($j = 1; $j < scalar(@params); $j++) {
			$replica[$n][$lut[$j-1]] = $params[$j];
			$last[$lut[$j-1]] = $params[$j];
			
		}
		$n++;

	}
	close(DAT);
}
for ($i = 0; $i < $n; $i++) {
	print "$i\t";
	for ($j = 0; $j < $rep; $j++) {
		print "$replica[$i][$j]\t";
	}
	print "\n";
}
