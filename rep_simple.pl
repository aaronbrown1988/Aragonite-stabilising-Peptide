#!/usr/bin/perl
#
# Usage rep_simple confout.gro
# This script takes a gro file, rplicates it in the C/Z direction and outputs an xyz.
# This was to aid in debugging the chitin slab
#

open(FH, "$ARGV[0]");
while (!eof(FH)) {
	$line = readline(FH);
}
$line =~ s/^\s+//;
@dim = split(/\s+/, $line);

seek(FH, 0, 0);
open(OUT, ">out.xyz");
$line = readline(FH);
$line = readline(FH);
chomp($line);
$line *= 2;
print OUT "$line\n";
print OUT "ALpha Chitin\n";
while($line = readline(FH)) {
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$params[1] = substr($params[1], 0, 1);
	$params[3] *= 10;
	$params[4] *= 10;
	$params[5] *= 10;
	print OUT "$params[1] $params[3] $params[4] $params[5]\n";
	$params[5] += ($dim[2]*10);
	print OUT "$params[1] $params[3] $params[4] $params[5]\n";

}
close(OUT);
close(FH);
