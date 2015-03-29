#!/usr/bin/perl
#
# Calculates the density in the centre of a box
#
#
# USAGE: [Folder] [dim] [start] [end]

opendir(DH, "$ARGV[0]") || die "Couldn't open $ARGV[0]:$!\n";
while ($file = readdir(DH)) {
	if ($file =~ /[0-9]+\.pdb/) {
		push(@files, $file);
	}
}
close(DH);
$start = $ARGV[2];
$end = $ARGV[3];
for ($i=0; $i < scalar(@files); $i++) {
	$nO = 0;
	$nH = 0;
	open(FH, "$ARGV[0]/$files[$i]");
	while ($line = readline(FH)) {
		@params = split(/\s+/, $line);
		if ($line =~ /^CRYST.*/) {
			@box = ($params[1],$params[2],$params[3]);
		} elsif ($line !~ /^ATOM/) {
			next;
		}
		if ($params[5] > $end || $params[5] <= $start) {
			next;
		} 
		if (($params[3] =~ /SOL/) && ($params[2] =~ /.*OW.*/)) {
			$nO ++;
		} elsif (($params[3] =~ /SOL/) && ($params[2] =~ /.*HW[12].*/)) {
			$nH++;
		}

	}
	$vol = ($end-$start)*$box[1] * $box[2];
	$vol *= 0.001;
	$densityA = ($nO * (18.0/6))/($vol*0.1);
	$density = $nO*15.9994 + $nH*1.008;
	$density = ($density*1.66)/$vol;

	$i = $files[$i];
	$i =~ s/.pdb//;
	print "$i\t$density\t$densityA\t$nO\t$nH\n";

	close(FH);


	
}
			

	
