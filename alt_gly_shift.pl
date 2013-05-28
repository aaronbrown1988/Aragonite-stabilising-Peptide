#! /usr/bin/perl

opendir(DIR, "$ARGV[0]" ) || die " Couldn't open directory $ARGV[0] for reading: $!\n";
open(ALT, ">alt_gly.tsv") || die "Couldn't open output file for writing:$!\n";
@HA=qw( 1 2 3);
@RES=qw(7 26);

while ($file = readdir(DIR)) {
	if (($file !~ /.+\.pdb\b/ ) || ($file =~ /.*camshift.*/)) {
		print "skipping $file\n";
		next;
	}
	open (PDB, "$ARGV[0]/$file") || die "Couldn't open $ARGV[0]/$file for reading: $!\n";
	open(OUT, ">out.pdb") || die " Couln't open temporary output file\n";
	while ($line = readline(PDB)) {
		if ($line =~ /.*HA.*GLY.*/) {
			$next = readline(PDB);
			$line =~ s/HA1/HA2/;
			$next =~ s/HA2/HA1/;
			print OUT $next;
			print OUT $line;
		} else {
			print OUT $line;
		}
	}
	close(PDB);
	close(OUT);
	$file =~ s/\.pdb//;
	$file *= 10;
	open(CAM,"-|", "camshift --data /Users/aaronbrown/local/share/camshift/data --pdb out.pdb") || die " Couldn't run Camshfit: $!\n";
	$i = 0;
	print ALT "$file";
	while ($line = readline(CAM)) {
		if ($line !~ /.*\sGLY\s.*/) {
			next;
		}
		$line =~ s/^\s+//;
		@params = split(/\s+/, $line);
		print ALT "\t$params[2]";
		$res[$i] = $params[0];
		$i++;
	}
	close(CAM);
	print ALT "\n";
#	unlink("out.pdb");
}
print ALT "#Time";
for ($j = 0; $j < $i; $j++) {
	print ALT "\t$res[$j]";
}
print ALT "\n";
close(ALT);

