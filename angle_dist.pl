#!/usr/bin/perl
#
# Takes a folder of PDB and analyses the angle of the
# the waters to see how 'random' they are
#

#USage angle_dist.pl folder last non-water start end dimension

#use Math::Vec;
use Math::Vector::Real;

$zlo = $ARGV[2];
$zhi = $ARGV[3];
$axis = $ARGV[4] + 4;

print "# going from $zlo to $zhi in $axis\n";

$str = 0.5;
$box = 5;

for ($i = 0; $i < $zhi/$str; $i++) {
	$adr[$i] = 0;
	$num[$i] = 0;
}

opendir(DH, "$ARGV[0]");
$nfiles = 0;
while ($file = readdir(DH)) {
	if ($file !~/[0-9]+\.pdb\b/) {
		next;
	}
	open(PDB, "$ARGV[0]/$file");
	$nfiles++;
	process();
	close(PDB);
	print STDERR "\b" x1000; 
	print STDERR "$nfiles processed";

}

for ($i = 0; $i < ($zhi/$str); $i++) {
#	print "$i\n";
	if ($num[$i] != 0) {
	#	print "$adr[$i]\n";
		$adr[$i] = $adr[$i] / ($num[$i]);
		$z = $zlo + $i*$str;
		print "$z\t$adr[$i]\t$num[$i]\n";
	}

}




sub process {
# ARGS pdb slab_end 
	$line = readline(PDB);
	
	while(!eof(PDB)) {
		# Move to water section
		while ($line = readline(PDB)) {
			@params = split(/\s+/, $line);
			if ($params[1] == $ARGV[1]) {
				last;
			}
		}
		$l = 0;
			
		while ($line = readline(PDB)) {
			if($line =~ /END.*/) {
				last;
			}
			$line =~ s/X1/X 1/;
			@lines[$l] = $line;
			$l++;
		}
		for ($i = 0; ($zlo +$i *$str) < $zhi; $i++) {
			$z = $zlo + $i*$str;
		#	print "$z:\n";
			for ($j = 0; $j < $l; $j += 3) {
				@params = split(/\s+/, $lines[$j]);
				if ($params[$axis] < ($zlo +$i*$str) || $params[$axis] > ($zlo +$i*$str+$box)) {
					next;
				}
			#	print $Ov,"\n";
				$Ov = V($params[5], $params[6],$params[7]);
				@params = split(/\s+/, $lines[$j+1]);
				$H1v = V($params[5], $params[6],$params[7]);
				@params = split(/\s+/, $lines[$j+2]);
				$H2v = V($params[5], $params[6],$params[7]);
		
				$a = 0.5*($H2v - $H1v);
				$a = $a + $H1v;
				$b = $a - $Ov;
				#$n = $a x $b;
		
				$dot = $b * V(1,0,0);
				$dot = $dot/ abs($b);
			#	print "$i\t$dot\n";
				$adr[$i] += $dot;
				$num[$i] ++;
			}
		}
	}
	@lines = undef();
}
	
