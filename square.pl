#!/usr/bin/perl
open (FH, $ARGV[0]) || die "Couldn't open $ARGV[0] $!\n";

while ($line = readline(FH)) {
	$line =~ s/X/ X /;
	@params = split(/\s+/, $line);
	if ($line =~ /^CRYST.*/) {
		$a = $params[1];
		$b = $params[2];
		$c = $params[3];
		$g = 180 - $params[6];
		$line = sprintf("%-7s %7.3f %7.3f %7.3f %7.2f %7.2f %7.2f %s %10s %s", 'CRYST1', $a+cos($g), $b*sin($g), $c, 90, 90, 90, 'P', '1', '1');
		print "$line\n";
		next;
	}
	$params[7] += $params[6] *cos($g);
	$params[6] *= sin($g);
	$line = sprintf("%s %7d %-4s %3s %1s %-5d %8.3f %7.3f %7.3f %6.3f %6.3f", $params[0], $params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$params[7],$params[8],$params[9],$params[10]);
	print "$line\n";
}
	
