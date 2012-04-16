#!/usr/bin/perl

open(FH, $ARGV[0]) || die "$!\n";

while($line = readline(FH)) {
	if ($line =~ /.*Bonds.*/) {
		last;
	}
}
$line = readline(FH);

while ($line = readline(FH)) {
	if (length($line) < 3) {
		last;
	}
	$line =~ s/^\t//;
	@params = split(/\s+/, $line);
	if ($params[1] == 1) {
		push(@a, $params[2]);
		push(@b, $params[3]);
	}
}
print "Angles\n\n";
$angles = 1+$ARGV[1];
for($i =0; $i < 270; $i ++) {
	for ($j = $i+1; $j < 270; $j++) {
		if ($a[$j] == $a[$i]) {
			print "\t$angles\t1\t$b[$i]\t$a[$i]\t$b[$j]\n";
			$angles++;
		} elsif ($a[$j] == $b[$i]) {
			print "\t$angles\t1\t$a[$i]\t$a[$j]\t$b[$j]\n";
			$angles++;
		} elsif ($b[$j] == $a[$i]) {
			print "\t$angles\t1\t$b[$i]\t$a[$i]\t$a[$j]\n";
			$angles++;
		}elsif ($b[$j] == $b[$i] ) {
			print "\t$angles\t1\t$a[$i]\t$b[$i]\t$a[$j]\n";
			$angles++;
		}
	}
}
