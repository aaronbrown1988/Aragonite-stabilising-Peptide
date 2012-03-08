#!/usr/bin/perl

open(INP, "$ARGV[0]");
open(OUT, ">$ARGV[0].fix");

$slab_id = $ARGV[1];
$slab_offset = $ARGV[2];

while ($line = readline(INP)) {
	print OUT $line;
	if ($line =~ /.*Atoms.*/) {
		last;
	}
}
$line = readline(INP);
print OUT $line;
while($line = readline(INP)) {
	if (length $line < 3) {
		last;
	}
	$line =~ s/#.*//;
#	$line =~ s/^\t//;
	@params = split (/\s+/, $line);
#	print "$params[2]\n";
	if ($params[2] == $slab_id) {
		print OUT $line;
		last;
	 } else {
		 $tmp = $params[5];
		 $params[5] = $params[7];
		 $params[7] = -$tmp+$slab_offset;
		 print OUT "$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\t$params[5]\t$params[6]\t$params[7]\n";

	 }
}
while (!eof(INP)) {
	$line = readline(INP);
	print OUT $line;
}


