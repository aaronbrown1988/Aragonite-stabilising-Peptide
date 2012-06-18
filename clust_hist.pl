#!/usr/bin/perl
####################################
# Clust size Histogram generator
################################
#
# Takes the output of clust_size and produces a histogram
#


open (INP, $ARGV[0]) || die "couldn't open $ARGV[0]: $!\n";

# read first line giving max cluster size
$line = readline(INP);
@params = split(/\s+/, $line);
$total = $params[1];
$max = 1;

for($i=0; $i <= $params[1]; $i++) {
	$hist[$i] = 0;
}

$hist[$total] ++;

while ($line = readline(INP)) {
	@params = split(/\s+/, $line);
	$hist[$params[1]] ++;
	$max = ($hist[$params[1]] > $max)? $hist[$params[1]]: $max;
}

close(INP);

open(OUT, ">clust_size_hist.tsv") || die "couldn't open clust_size_hist for writing: $!\n";

print OUT "#size\tcount\tNormalized\n";
for($i=0; $i <= $total; $i++) {
	$x = $hist[$i]/ $max;
	print OUT "$i\t$hist[$i]\t$x\n";
}


	



