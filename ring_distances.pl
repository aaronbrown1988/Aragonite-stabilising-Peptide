#!/usr/bin/perl
use POSIX;
$bx = 1e99;
$by = 1e99;
$bz = 1e99;

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
	while ($line = readline(FH)) {
		if ($line =~ /CRYST1.*/) {
			@params = split(/\s+/,$line);
			$bx = @params[1]/2;
			$by = @params[2]/2;
			$bz = @params[3]/2;
#	print "#Found PBC's $bx $by $bz\n";
			last;
		}
	}
	seek(FH, 0, 0);
	while($line = readline(FH)) {
		$line = checkline($line);
		@params = split(/\s+/, $line);
		if ($params[3] eq "PHE" || $params[3] eq "TYR" ||$params[3] eq "TRP"  ||$params[3] eq "ILE" ||$params[3] eq "HIS") { # || $params[3] eq "GLY") {
			#Found an aromatic/ aliphatic residue.
			@coords = find_center($line);
			#	print "$params[3]-$params[4] : @coords\n";
			$pos_new = tell(FH);
			while ($line = readline(FH)) {
				$line = checkline($line);
				@params2 = split(/\s+/, $line);
				$chA = $params[4];
				$rA = $params[4];
				$chB = $params2[4];
				$rB = $params2[4];
				$rA =~ s/[A-Z]//g;
				$chA =~ s/[0-9]//g;	
				$rB =~ s/[A-Z]//g;
				$chB =~ s/[0-9]//g;

				if (($params2[3] eq "PHE" || $params2[3] eq "TYR" ||$params2[3] eq "TRP"  ||$params2[3] eq "ILE" || $params2[3] eq "HIS") && (($chA eq $chB && $rB != ($rA+1)) || ($chA ne $chB) )) {#|| $params2[3] eq "GLY") {
					@coords2 = find_center($line);
					#	print "$params2[3]-$params2[4] : @coords2\n";
					$dx = ($coords[0] - $coords2[0]);
					$dy = ($coords[1] - $coords2[1]);
					$dz = ($coords[2] - $coords2[2]);
					
					$dx = ($dx**2 > $bx**2)? (abs($dx)-(2*$bx)):$dx;

					$dy = ($dy**2 > $by**2)? (abs($dy)-(2*$by)):$dy;

					$dz = ($dz**2 > $bz**2)? (abs($dz)-(2*$bz)):$dz;

					$dist = ($dx)**2;
					$dist += ($dy)**2;
					$dist += ($dz)**2;
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




sub find_center
{
	my $x,$y,$z;
	my $res;
	my $n=0;
	my $line;
	$line = $_[0];
	@par = split(/\s+/, $line);
	$res = $par[4];
	$x = 0;
	$y = 0;
	$z = 0;
	#	print "DEBUG: $res from $line from $_[0]\n";
	while ($par[4] == $res) {
		if ($par[2] =~ /.*C[DEGZ].*/ && $par[3] ne "ILE") {
			$x += $par[5];
			$y += $par[6];
			$z += $par[7];
			$n++;
		} elsif (($par[3] eq "GLY" && $par[2] =~ /.*N*.*/) || ($par[3] eq "ILE" && $par[2] =~ /.*CA.*/)) {
			$x += $par[5];
			$y += $par[6];
			$z += $par[7];
			$n++;
		}
		$line = readline(FH);
		$line = checkline($line);
		@par = split(/\s+/, $line);
		
	}
#print "$n, $x, $y,$z\n";		
	$x /= $n;
	$y /= $n;
	$z /= $n;
	@ret = ($x,$y,$z);
#	print "DEBUG: found $n compatible atoms, @ret == $x $y $z\n";
	return(@ret);
	
	
}
sub checkline {
	my $orig=$_[0];
	my @fields;
	@fields = split(/\s+/, $orig);
	if($fields[4] !~ /[0-9]+/) {
		$orig =~ s/\s+$fields[5]\s+/ $fields[5]$fields[4] /;
		$orig =~ s/ $fields[4] / /;
	}
	return($orig);
}
