#!/usr/bin/perl

if ($ARGV[0] == undef) {
	die " Need number of clusters to work over";
}

my $nclusts=$ARGV[0];
my $cutoff = $ARGV[1];
my @out_order;
my @out_LUT;
my @rmsd;
my $nframes;
my $matched = 0;

for ($i = 0; $i < $nclusts; $i++ ) {
	open (FH, "$i.xvg") || die "Can;t open $i.xvg:$! \n";
	$buildLUT = 0;
	if (@frameLUT == undef) {
		$buildLUT = 1;
	}
	my $j = 0;
	while ($line = readline(FH)) {
		if ($line =~ /^[@#].*/) {
			next;
		}
		$line =~ s/^\s+//;
		@params = split(/\s+/, $line);
		if($buildLUT != 0) {
			push(@frameLUT, $params[0]);
		}
		$rmsd[$i][$j] = $params[1];
		
		if ($params[1] <= $cutoff) {
			$clust_size[$i] ++;
		}
		$j++;
	}
	$nframes = $j;
	close(FH);
}

print "$rmsd[0][0]\n";

open(RMSD, ">rmsd_map.tsv");
for ($i = 0; $i < $nclusts; $i ++) {
	for ($j = 0; $j < $nframes; $j++) {
		print RMSD"$i\t$j\t$rmsd[$i][$j]\n";
	}
	print RMSD "\n";
}
close(RMSD);

open (LOG, ">recluster.log");

print LOG "ID\tOld\tNMembers\tMembers\n";
print LOG '-' x 80;
print LOG "\n";

for ($i = 0; $i < $nclusts; $i++) {
	$n = daura($i);
	if ($n == 0) {
		print "No complete matches possible given these centroids\n";
		print "$i/$nclusts match some of the frames \n";
		$percent = $matched/$nframes;
		$percent *= 100;
		print "$matched/$nframes match one of the centroids given ($percent)\n";
		last;
	}
	
}

open (CLID, ">reclust-id.xvg" );

for ($i = 0; $i < $nframes; $i++) {
	print CLID "$frameLUT[$i]\t$out_LUT[$i]\n";
}
close(CLID);

sub daura {
	my $maxc=0;
	my $maxv=0;
	my $i=0;
	my $j=0;
	my $n=0;
	
	$cc = $_[0];

	for ($i =0; $i < $nclusts; $i++) {
		$n = 0;
		for ($j = 0; $j < $nframes; $j++ ) {
			if ($rmsd[$i][$j] <= $cutoff) {
				$n++;
			}
		}
		if ($n > $maxv) {
			$maxv = $n;
			$maxc = $i;
		}
	}
	$out_order[$cc] = $maxc;

	print LOG "$cc\t$maxc\t$maxv";
	
	for ($j = 0; $j < $nframes; $j++) {
		if ($rmsd[$maxc][$j] <= $cutoff) {
			print LOG "\t$frameLUT[$j]";
			for ($i = 0; $i < $nclusts; $i++ ) {
				$rmsd[$i][$j] = 9e99;
			}
			$matched ++;
			$out_LUT[$j] = $cc;

		}
	}
	print LOG "\n";
	print LOG '-' x 80;
	print LOG "\n";
	$cc++;
	return($maxv);
}
close(LOG);












