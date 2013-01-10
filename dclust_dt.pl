#!/usr/bin/perl
#This script runs over the output of clust_time to give dc/dt. In a very rough way
# USAGE: dclust_dt.pl clust_time.xvg dt
$dx = ($ARGV[1] == undef )? 50: $ARGV[1];
print "#dt = $dt\n";
open(FH, "$ARGV[0]") || die "$!\n";
while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
	$line =~ s/^\s+//;
	push(@buff, $line);
}
close(FH);

for ($i = $dx; $i < (scalar(@buff) - $dx ); $i+= $dx) {
	$j = $i - $dx;
	$k = $i + $dx;
	$line = $buff[$j];
#print $line;
	@A = split(/\s+/, $line);

	$line = $buff[$k];
#	print $line;
	$A[0] /= 1e6;
	@B = split(/\s+/, $line);
	$B[0] /= 1e6;
#print "#$i: $j:@A and $k:@B\n";
	$dt = ($B[1] - $A[1])/($B[0]-$A[0]);
	@params = split(/\s+/, $buff[$i]);
	$params[0] /= 1e6;
	print "$params[0] \t$dt\n";
}

