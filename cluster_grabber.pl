#!/usr/bin/perl
# Grabs all the pdbs relating to a cluster.
# usage clust_grabber cluster.log raw_pdbs

open(FH, "$ARGV[0]") || die "couldn't open $ARGV[0]: $!\n";

$raw = $ARGV[1];

while ($line = readline(FH)) {
	if ($line =~ /^cl\..*/) {
		last;
	}
}

while ($line = readline(FH)) {
	@params = split (/ \| /, $line);
	if ($params[0] =~ /[0-9]+/) {
		$cur_clust = $params[0];
		$cur_clust =~ s/ //g;
		$mid = $params[2];
		if ($cur_clust > 5) {
			last;
		}
		mkdir "$raw/clust_$cur_clust";
	}
	$params[3] =~ s/^\s+//;
	@members = split(/\s+/, $params[3]);

	print "$params[3]\n";
	for ($i = 0; $i < @members; $i++) {
		$members[$i] /= 10;
		print "linking $members[$i] to $raw/clust_$cur_clust/$members[$i].pdb\n";
		link("$raw/$members[$i].pdb", "$raw/clust_$cur_clust/$members[$i].pdb") || die "Couldn't make link $members[$i] to $raw/clust_$cur_clust/$members[$i].pdb:$!\n" ;
	}
}
close(FH);


