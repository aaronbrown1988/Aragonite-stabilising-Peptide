#!/usr/bin/perl
#
# Generate an awesomje contour map from the RMSD of clusters.
#

open(CL, $ARGV[0]) || die "couldn't open $ARGV[0] for reading: $!\n";
open(RMSD, $ARGV[1]) || die "couldn't open $ARGV[1] for reading: $!\n";

$i = 1;
while ($line = readline(CL)) {
	$line =~ s/^\s+//;
	if ($line =~ /^[0-9].*/) {
		@params = split(/ \| /, $line);
		$params[2] =~ s/^ +//;
		$params[2] =~ s/ +\..*//;
		$params[2] =~ s/ +//;
		push(@structs, $params[2]);
		$reorder{$params[2]} = $i;
		$i++
	}
}
close(CL);
#@structs = sort {$a <=> $b} @structs;
#print "@structs\n";

while ($line = readline(RMSD)) {
	if ($line =~ /static.*/) {
		last;
	}
}
$line = readline(RMSD);
for ($i = 0; $i < 40; $i ++) {
	$line = readline(RMSD);
	$line =~ s/\"//g;
	@params = split(/\s+/, $line);
#	print "$params[0] = $params[4]\n";
	$lut{$params[0]} =  $params[4];  # populate lookup table

}
# Skip Comments section

while ($line = readline(RMSD)) {
	if (!($line =~ /\/\*.*/)) {
		last;
	}
}
#@structs = qw( 29740 );
#print $line;
$start = tell(RMSD);
$cur_row = 0;
foreach $a (@structs) {
	#	print $line;
	$j = 0;
	foreach $b (@structs) {
		if( $b < $a) {
			next;
		} else {
		$b = $b/10;
		$c = 2974 - $b;
	#	$c = $b;
		seek(RMSD, $start, 0);
		for ($i = 0; $i < $c; $i++) {
			$line = readline(RMSD);
		}
	#	print "$a\n";
		$cur_row += $c;
		$b = $b * 10;
		$line =~ s/\"//g;

		$a = $a / 10;
		$val = substr($line,$a-1, 1);
		#print "$line => $b\t$val\n";
	#	print "$a\n";
		$a = $a * 10;
		if ( $val eq "") {
			print "$line\n"
		}
		print "$reorder{$a}\t$reorder{$b}\t$lut{$val}\t$a\t$b\t$val\n";
	#	print "$a\t$b\t$val\n";
		$j++;
		if ($j > 4) {
			$j = 0;
			print "\n";
		}
		}
	}
#	print "\n";
}


