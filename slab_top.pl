#!/usr/bin/perl
#
# Find the 'top' of a slab in a given direction
# USAGE slab_top raw DIREC ATM_NAME CUT;
# OUPUT: file TOP BOTTOM

opendir(RAW, "$ARGV[0]") || die "Couldn't open Raw folder $ARGV[0]: $!\n";

while($line =readdir(RAW)) {
	if($line =~ /.*\.pdb/) {
		$line =~ s/.pdb//;
		push(@files, $line);
	}
}
@files = sort {$a <=> $b} @files;
for ($i = 0; $i < @files; $i++) {
	open(FH, "$ARGV[0]/$files[$i].pdb") || die "Couldn't open $ARGV[0]/$files[$i].pdb : $!\n";
	@heights = qw();
	while ($line = readline(FH)) {
		if ($line !~ /^ATOM.*/) {
			next;
		}
		$line =~ s/ [A-Z] //;
		@params = split(/\s+/, $line);

		if ($params[2] =~ /.*$ARGV[2].*/ ) {
			push(@heights, "$params[4+$ARGV[1]]");
		}
	}
	@heights = sort {$b <=> $a} @heights;
	$h = 0;
	$n = 0;
#	print "@heights\n";
	for ($j = 0; $j < (scalar(@heights)/2); $j ++) {
		if ($j !=0 && (($heights[$j] - $heights[$j-1])**2 > $ARGV[4]**2)) {
			last;
		}
			$h += $heights[$j];
			$n++;
	}
	$h /= $n;
	$nt = $n;
	@heights = sort {$a <=> $b} @heights;
	$b = 0;
	$n = 0;
#	print "@heights\n";
	for ($j = 0; $j < (scalar(@heights)/2); $j ++) {
		if ($j !=0 && (($heights[$j] - $heights[$j-1])**2 > $ARGV[4]**2)) {
			last;
		}
			$b += $heights[$j];
			$n++;
	}
	$b /= $n;

	print "$files[$i]\t$h\t$b\t$nt\t$n\n";
#print "$n\n";
#	print scalar(@heights);

#	exit;
}
print "# n = $n\n";


