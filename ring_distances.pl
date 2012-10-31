#!/usr/bin/perl
use POSIX;

opendir(DH, $ARGV[0]) || die "couldn't open $ARGV[0]: $!n";

while ($file = readdir(DH)) {
	if($file !~ /.*pdb/){
		next;
	} elsif ($file =~ /.*pdb.+/) {
		next;
	}
	$step = $file;
    $step =~ s/\.pdb//;
	print "$step";
	open(FH, "$ARGV[0]/$file") || die  "couldn't open $file,: $!\n";
	@pairs = qw();
	while($line = readline(FH)) {
		@params = split(/\s+/, $line);
		if ($params[3] eq "PHE" || $params[3] eq "TYR" ||$params[3] eq "TRP"  ||$params[3] eq "ILE") { # || $params[3] eq "GLY") {
			#Found an aromatic/ aliphatic residue.
			@coords = find_center($line);
			#	print "$params[3]-$params[4] : @coords\n";
			$pos_new = tell(FH);
			while ($line = readline(FH)) {
				@params2 = split(/\s+/, $line);
				if ($params2[3] eq "PHE" || $params2[3] eq "TYR" ||$params2[3] eq "TRP"  ||$params2[3] eq "ILE" ) {#|| $params2[3] eq "GLY") {
					@coords2 = find_center($line);
					#	print "$params2[3]-$params2[4] : @coords2\n";
					$dist = ($coords[0] - $coords2[0])**2;
					$dist += ($coords[1] - $coords2[1])**2;
					$dist += ($coords[2] - $coords2[2])**2;
					$dist = sqrt($dist);
					$pair = "$params[3]$params[4]-$params2[3]$params2[4]";
					push (@pairs, $pair);
					print ",\t$dist";
				}
					
					
			}
			seek(FH,$pos_new,0);
		}
	}
	print "\n";
	#print "\n# $step @pairs\n";
	
}
for ($i = 0; $i < @pairs; $i++) {
	print "\@ s$i legend \"$pairs[$i]\"\n";
	print "\@ s$i hidden false\n";
	print "\@ s$i on\n";


}
for ($i = 0; $i < @pairs; $i++) {
	print "\@ sort s$i X ascending\n";
}




sub find_center
{
	my $x,$y,$z;
	my $res;
	my $n;
	my $line;
	$line = $_[0];
	@par = split(/\s+/, $line);
	$res = $par[4];
	$x = 0;
	$y = 0;
	$z = 0;
	#	print "DEBUG: $res from $line from $_[0]\n";
	while ($par[4] == $res) {
		if ($par[2] =~ /.*C[DEGZ].*/) {
			$x += $par[5];
			$y += $par[6];
			$z += $par[7];
			$n++;
		} elsif (($par[3] eq "ILE" || $par[3] eq "GLY") && ($par[2] =~ /.*C[BA]*.*/)) {
			$x += $par[5];
			$y += $par[6];
			$z += $par[7];
			$n++;
		}
		$line = readline(FH);
		@par = split(/\s+/, $line);
		
	}
		
	$x /= $n;
	$y /= $n;
	$z /= $n;
	@ret = ($x,$y,$z);
	#print "DEBUG: found $n compatible atoms, @ret == $x $y $z\n";
	return(@ret);
	
	
}