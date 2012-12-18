#!/usr/bin/perl
#
# Calculates the minimum distance between the peptide and ions
# usage ion-dist traj.pdb

open(FH, "$ARGV[0]") || die " Couln't open $ARGV[0] for reading: $!\n";
print "# Time\t minimum Distance\tTime\n";
while ($line = readline(FH)) {
	@ions = qw();
	@peptide = qw();
	while ($line !~ /ENDMDL.*/) {
		if ($line =~ /CRYST1.*/) {
	   		@params = split(/s+/, $line);
			$bx = $params[1]/2;
			$by = $params[2]/2;
			$bz = $params[3]/2;
	 	} elsif ($line =~ /ATOM.*/) {
			chomp($line);
			@params = split(/\s+/,$line);
			if ($params[3] =~ /C[AL].*/) {
				push (@ions, $line);
			} else {
				push (@peptide, $line);
			}
	  	} elsif ($line =~ /TITLE.* t=.*/) {
			$line =~ s/.*t=\s+//;
			chomp($line);
			$time = $line;
		}
		$line = readline(FH);
	}
	$mindist = 1e99;
	for($i = 0; $i < @ions; $i++) {
		@ip = split(/\s+/, $ions[$i]);
		for ($j = 0; $j < @peptide; $j++) {
			@pp = split(/\s+/, $peptide[$j]);
			$dx = $ip[5] - $pp[5];
			$dy = $ip[6] - $pp[6];
			$dz = $ip[7] - $pp[7];

			$dx = ($dx**2 > $bx**2)? (abs($dx)-(2*$bx)): $dx;
			$dy = ($dy**2 > $by**2)? (abs($dy)-(2*$by)): $dy;
			$dz = ($dz**2 > $bz**2)? (abs($dz)-(2*$bz)): $dz;

			$dist = $dx**2 + $dy**2 + $dz**2;
			$dist = sqrt($dist);

			if($mindist > $dist) {
				$mindist = $dist;
				$minpair = "$ip[2]:$ip[1] - $pp[1]:$pp[2]$pp[3]";
			
			}
		}
	}
	print "$time\t$mindist\t$minpair\n";


}
close(FH);	  
