#!/usr/bin/perl


#
# Compares Camshift output to NMR 
#

open(CS, $ARGV[0]) || die "$!\n";
open(NMR, $ARGV[1]) || die "$!\n";

while ($line = readline (CS)) {
	if($line =~ /\-\-\-+.+/) {
			last;
	}
}


$clust = $ARGV[0];
$clust =~ s/\..+//;

open (DIFF, ">$clust.shift-diffs") || die "$!\n";


$rms_ha =0;
$rms_hn = 0;
$rms_tot = 0;
$n =0;
print "#Cluster\tHA\tHN\t combined\n";
while ($line = readline(CS)) {
	$nmr = readline(NMR);
	@nmr_val = split(/,/, $nmr);
	@cshift = split(/\s+/, $line);
	if ($chsift[1] != 1 && $cshift[1] != 30) {
		$dha = $nmr_val[2] - $cshift[3];
		$dhn = $nmr_val[1] - $cshift[5];
		print DIFF "$chsift[1]\t$dha\t$dhn\n";
		$rms_ha += ($nmr_val[2] - $cshift[3])**2;
		$rms_hn += ($nmr_val[1] - $cshift[5])**2;
		$n++;
	}
}

$rms_tot = $rms_ha +$rms_hn;
$rms_tot = sqrt($rms_tot/ (2*$n));
$rms_ha = sqrt( $rms_ha / $n);
$rms_hn = sqrt( $rms_hn / $n);


print "$clust\t$rms_ha\t$rms_hn\t$rms_tot\n";

close(CS);
close(DIFF);
close(NMR);
