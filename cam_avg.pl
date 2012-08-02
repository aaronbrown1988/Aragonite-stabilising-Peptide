#!/usr/bin/perl

# Loops over .camshift files and produces an average of them
opendir(CUR, "$ARGV[0]");
$res = $ARGV[1];
for ($i = 0; $i <= $res; $i++) {
	@ha[$i] = 0;
	@ca[$i] = 0;
	@hn[$i] = 0;
	@n[$i] = 0;
	@c[$i] = 0;
	@cb[$i] = 0;
}
$n  = 0;
while ($file = readdir(CUR)) {
	if ($file =~ /.*\.camshift/) {
		open(IN, "$ARGV[0]/$file");
		while ($line = readline($line)) {
			if ($line =~ /.*ID.*/) {
				last;
			}
		}
		$line = readline(IN);
		while($line = readline(IN)) {
			$line =~ s/^\s+//;
			@params = split(/\s+/, $line);
			$ha[$params[0]] += $params[2];
			$ca[$params[0]] += $params[3];
			$hn[$params[0]] += $params[4];
			$n[$params[0]] += $params[5];
			$c[$params[0]] += $params[6];
			$cb[$params[0]] += $params[7];
		}
		close(IN);
		$n++;
	}
}
for ($i = 1; $i <= $res; $i++) {
	$ha[$i]/= $n;
	$ca[$i] /=  $n;
	$hn[$i] /=  $n;
	$n[$i] /=  $n;
	$c[$i] /=  $n;
	$cb[$i] /=  $n;
	print "$i\t$ha[$i]\t$ca[$i]\t$hn[$i]\t$n[$i]\t$c[$i]\t$cb[$i]\n";
}

