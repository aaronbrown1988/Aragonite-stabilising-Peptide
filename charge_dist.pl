#!/usr/bin/perl
use POSIX;
$bx = 1e99;
$by = 1e99;
$bz = 1e99;

my @neg;
my @pos;

#Args dir_with_pdbs output;
opendir(DH, $ARGV[0]) || die "couldn't open $ARGV[0]: $!\n";

while ($file = readdir(DH)) {
    if ($file !~ /.*pdb/) {
        next;
    }
	if ($file =~ /.*pdb.+/){
		next;
	}
    $step = $file;
    $step =~ s/\.pdb//;
    print "$step";
	open(FH, "$ARGV[0]/$file") || die  "couldn't open $file,: $!\n";
	@pairs = qw();
	while ($line = readline(FH)) {
	if ($line =~ /CRYST1.*/) {
		@params = split(/\s+/,$line);
		$bx = @params[1]/2;
		$by = @params[2]/2;
		$bz = @params[3]/2;
		#print "#Found PBC's $bx $by $bz\n";
		last;
		}
	}
	seek(FH, 0, 0);
    while ($line = readline(FH)) {
        $line =~ s/^\s+//;
        @params = split(/\s+/, $line);
		if($params[2] eq "CG" && ($params[3] eq "ASP" || $params[3] eq "GLU")) {
            $pos = tell(FH);
            while($line = readline(FH)) {
                @params2 = split(/\s+/, $line);
		if((($params2[2] eq "CZ" && $params2[3] eq "ARG" ) || ( $params2[3] eq "LYS" &&  $params2[2] eq "NZ")) && $params2[4] != ($params[4]+1)) { 
                    $dx = ($params[5] - $params2[5]);
                    $dy = ($params[6] - $params2[6]);
					$dz= ($params[7] - $params2[7]);
			#print "#dx: $dx dy: $dy dz: $dz\n";
			$dx = ($dx**2 > $bx**2)? (abs($dx)-(2*$bx)):$dx;
			$dy = ($dy**2 > $by**2)? (abs($dy)-(2*$by)):$dy;
			$dz = ($dz**2 > $bz**2)? (abs($dz)-(2*$bz)):$dz;
			$dist = ($dx)**2;
			$dist += ($dy)**2;
			$dist += ($dz)**2;
			
                    $dist = sqrt($dist);
                    print "\t$dist";
					$pair = "$params[3]$params[4]-$params2[3]$params2[4]";
					push(@pairs,$pair);
				}
			}
			seek(FH, $pos, 0);
		}
		if(($params[2] eq "CZ" && $params[3] eq "ARG" ) || ( $params[3] eq "LYS" &&  $params[2] eq "NZ") ) {
			$pos = tell(FH);
			while($line = readline(FH)) {
				@params2 = split(/\s+/, $line);
				if (($params2[2] eq "CG" && ($params2[3] eq "ASP" || $params2[3] eq "GLU" ))  && $params2[4] != ($params[4] +1)) {
					$dx = ($params[5] - $params2[5]);
                    $dy = ($params[6] - $params2[6]);
					$dz= ($params[7] - $params2[7]);
					#print "#dx: $dx dy: $dy dz: $dz\n";
					$dx = ($dx**2 > $bx**2)? (abs($dx)-(2*$bx)):$dx;
					$dy = ($dy**2 > $by**2)? (abs($dy)-(2*$by)):$dy;
					$dz = ($dz**2 > $bz**2)? (abs($dz)-(2*$bz)):$dz;
					$dist = ($dx)**2;
					$dist += ($dy)**2;
					$dist += ($dz)**2;
					print "\t$dist";
					$pair = "$params[3]$params[4]-$params2[3]$params2[4]";
					push(@pairs,$pair);
				}
			}
			seek(FH, $pos, 0);
		}
			
	}
	print "\n";
	#print "\n# step @pairs\n";
	#exit;
}
for ($i = 0; $i < @pairs; $i++) {
	print "\@ s$i legend \"$pairs[$i]\"\n";
	print "\@ s$i hidden false\n";
	print "\@ s$i on\n";
	
	
}
for ($i = 0; $i < @pairs; $i++) {
	print "\@ sort s$i X ascending\n";
}
