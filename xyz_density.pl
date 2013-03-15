#!/usr/bin/perl
#
# Density Calulator
#
#
# USAGE RAW SLAB_bounds direction
# direction = 1,2,3

my $direction = $ARGV[2];
$|=1;

my $file;
my @lattice;
my @box_angles;
my @slab;
#Configuration

$boxes = 50;
$wind_size = 1.5;
$stride = 0.2;
#$act = 9.97e-25; # g/(Angstrom^3)
$act = 9.97e-2; # reduced power




#Fill density with zeros;
for ($i = 0; $i < $boxes; $i++) {
	$box[$i] = 0;
}

opendir(RAW, "$ARGV[0]") || die "couldn't open dir: $ARGV[0]: $! \n";
open(BOUNDS, "$ARGV[1]") || die " Couldn't open $ARGV[1] for  slab bounds:$!\n";

while ($line = readdir(RAW)) {
	if ($line =~ /.*pdb/ ) {
		push(@files, $line);
	}
}
closedir(RAW);
@files = sort {$a <=> $b } @files;
for ($i = 0; $i < 500; $i++) { # scalar(@files); $i++) { 
	$file = $files[$i];
#print "$file...";
	open(DATA, "$ARGV[0]/$file") || die "Failed to open $raw/$file:$!";
	$found = 0;
	while($line = readline(DATA)) {
		if($line =~ /^CRYST1.*/ ) {
			@params = split(/\s+/, $line);
			push (@lattice, $params[1]);
			push (@lattice, $params[2]);
			push (@lattice, $params[3]);
			push (@box_angles, $params[4]);
			push (@box_angles, $params[5]);
			push (@box_angles, $params[6]);
			$found = 1;
			last;
		}
	}
	if ($found != 1) {
		printf "Couldn't get dimensions for $file, skipping\n";
		next;
	}
	
	$stride = $lattice[$direction -1] / (2*$boxes);

	@slab = qw();
	# get the precomputed slab boundary
	while($bounds = readline(BOUNDS)) {
		@params = split(/\s+/,$bounds);
		if ($params[0] == $file) {
			push (@slab, $params[1]);
			push (@slab, $params[2]);
			last;
		}
	}
	# Skip on to the WATER
	@water = qw();
	while ($line = readline(DATA)) {
		@params = split(/\s+/, $line) ;
		if ($params[3] =~ /.*SOL.*/ && $params[2] =~ /.*OW.*/ ) {
			# Save the O positions
			push(@water ,"$params[5] $params[6] $params[7]");
			 
		}
	}
	close(DATA);
	
	$vol = ($lattice[0] *$lattice[1] *$lattice[2] *2 *$wind_size)/$lattice[$direction-1];
	
	#Count number in each box 
	for ($l = 0; $l < $boxes; $l++) {
		$density = 0;
		for ($j = 0; $j < scalar(@water); $j++ ) {
			@coords = split (/\s+/, $water[$j]);
			if ($coords[$direction-1] < ($slab[0]+($l+1)*$stride+$wind_size) && $coords[$direction-1] > ($slab[0]+($l)*$stride+$wind_size)) {
				$density ++;
			}
			#check the bottom
			elsif ($coords[$direction-1] > ($slab[1] - ($l+1)*$stride - $wind_size) && $coords[$direction-1] < ($slab[1]-$l*$stride-$wind_size)) {
				$density++;
			}
			# We should also check the periodic image for the bottom
			elsif (($coords[$direction-1]-$lattice[$direction-1]) > ($slab[1] - ($l+1)*$stride - $wind_size) && ($coords[$direction-1]-$lattice[$direction-1]) < ($slab[1]-$l*$stride-$wind_size)) {
				$density++;
			}
		}
		$density =$density / $vol; # Number per A^3
		#$density *= 0.001; # Number per nm^3
		$density *= (18/6); # g/nm^3
		$box[$l] += $density;
	}
	print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b$file";
}



open(OUT, ">density.tsv");
for ($i = 0; $i < $boxes; $i++) {
	$density = $box[$i]/scalar(@files);
	$mid = $i*$stride + 0.5 * $wind_size;
	print OUT "$mid\t$box[$i]\t$density\n";
}
close(out);
print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bDone\n";
