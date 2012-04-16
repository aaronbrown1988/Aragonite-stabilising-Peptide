#!/usr/bin/perl
#
# Compares gchi output to NMR 
#

open(GC, $ARGV[0]) || die "$!\n";
open(NMR, $ARGV[1]) || die "$!\n";

while ($line = readline (GC)) {
	if($line =~ /\-\-\-+.+/) {
			last;
	}
}


$clust = $ARGV[0];
$clust =~ s/\..+//;

open (DIFF, ">$clust.coupl-diffs") || die "$!\n";


$rms1 = 0;
$rms2 = 0;
$rms = 0;
$n =0;

while($nmr = readline(NMR)) {
	@nmr_val = split(/\s+/,$nmr);
	while ($line = readline(GC)) {
		if(length($line) < 4) {
			last;
		}
		@gc = split(/\s+/, $line);
		$gc[0] =~ s/[A-Z]//g;
		if ($nmr_val[0] eq $gc[0]) {
			$j = $gc[1] + $gc[3];
			$dj1 = $nmr_val[1] - $gc[1];
			$dj2 = $nmr_val[1] - $gc[3];
			$dj = $nmr_val[1] - $j;
			print DIFF "$nmr[0]\t$j\t$dj1\t$dj2\t$dj\n";
			$rms1 += ($dj1)**2;
			$rms2 += ($dj2)**2;
			$rms += ($dj)**2;

			$n++;
			last;
		}
	}
}


$rms1 = sqrt( $rms1 / $n);
$rms2 = sqrt( $rms2 / $n);
$rms = sqrt( $rms / $n);


print "$clust\t$rms1\t$rms2\t$rms\n";

close(CS);
close(DIFF);
close(NMR);
