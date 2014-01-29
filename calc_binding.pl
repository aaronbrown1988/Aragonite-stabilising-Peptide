#!/usr/bin/perl

open(FH, "$ARGV[0]") || die " Couldn't open $ARGV[0]: $!\n";

$bulk_start = 3;

while ($line = readline(FH)) {
	if ($ine =~ /^[#@].*/) {
		next;
	}
	$line =~ s/^\s//;
	push (@buffer,$line);
}
close (FH);

$min = 1e99;
$n=0;
$bulk = 0;
$ebulk = 0;
$emin = 0;
for ($i = 0; $i < @buffer; $i++ ) {
	@params = split(/\s+/, $buffer[$i]);
	if ($params[0] >= $bulk_start) {
		$bulk += $params[1];
		$ebulk+= $params[2];
		$n++;
	} else {
		$emin = ($params[1] < $min)? $params[2]:$emin;
		$min = ($params[1] < $min)? $params[1]:$min;
		
	}
}
$ebulk = $ebulk/$n;
$err = sqrt($ebulk**2 +$emin**2);
$dg = $min-($bulk/$n);
print "$ARGV[1]\t$dg\t$err\n";#\t$ebulk\t$emin\n";
