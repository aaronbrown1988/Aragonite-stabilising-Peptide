#!/usr/bin/perl
#
# Finds h bonds. Takes a folder of pdb's as the argument.
#
use Math::Trig;
@atypes=qw(C N O F);
my @pairs = qw();
my @bonds = qw();
$folder = $ARGV[0];
opendir(DH, "$ARGV[0]") || die "couldn't open $ARGV[0]: $!\n";
open(BD, ">Bond_data.dat");
while ($file = readdir(DH)) {
	if ($file =~ /.*\.pdb/ && $file !~ /.pdb.+/) {
		process();
		#last;
		#exit;
	}
}
closedir(DH);


print <<END;
@ s0 legend "# bonds"
@ s0 hidden flase
@ s0 on
@ s1 legend "# BB bonds"
@ s1 hidden flase
@ s1 on
@ s2 legend "# SC-SC bonds"
@ s2 hidden flase
@ s2 on
@ s3 legend "# SC-BB bonds"
@ s3 hidden flase
@ s3 on
@ sort s0 X ascending
@ sort s1 X ascending
@ sort s2 X ascending
@ sort s3 X ascending
END






sub process
{
	my @accept = qw();
	my @donor = qw();
	my @donorH = qw();
	my @peptide = qw();
	open(FH, "$folder/$file") || die "couldn't open $folder/$file :$!\n";
	while($line = readline(FH)) {
		if ($line !~ /.*ATOM.*/) {
			next;
		}
		push(@peptide, $line);
	}
	close(FH);
	
	#Look for suitable Heavy Atoms
	for ($i = 0; $i < @peptide; $i++) {
		$line = $peptide[$i];
		@params = split (/\s+/, $line);
		if ($params[2] !~ /^[CFON].*/) {
			#Give up if not the right type;
			next;
		}
		#Check for associated Hydrogens
		$isdonor = 0;
		$curRes = $params[4];
		$params2[4] = $curRes;
		for ($j = ($i+1); $j < @peptide; $j++) {
			$line = $peptide[$j];
			@params2 = split(/\s+/,$line);
			if ($params2[4] != $curRes) {
				last;
			} elsif ($params2[2] !~ /^H.*/) {
				next;
			}
			#Calculate the distance to the H
			$dist = ($params[5] - $params2[5])**2;
			$dist += ($params[6] - $params2[6])**2;
			$dist += ($params[7] - $params2[7])**2;
			$dist = sqrt($dist);
			if ($dist > 1.1) {
				next;
			} 
			# If we get here were a hydrogen associated with the Heavy found above.
			if ($isdonor == 0) {
				push(@donor, "$i");
				$donorH[@donor-1] = $j;
				$isdonor++;
				#print "$params[1] and $params2[1]\n";
#				exit;
			} else {
				$donorH[@donor -1] = "$donorH[@donor -1] $j";
				#	print "$params[1] and $params2[1]\n";
			}
				
		}
		if ($isdonor == 0) {
			push(@accept, "$i");
		}

	}

	#print "D:@donor\nA:@accept\nH:@donorH\n";
	#loop through donors
	$nbonds = 0;
	$scsc = 0;
	$bb = 0;
	$scb = 0;
	@pairs = qw();
	@bonds = qw();
	for ($i = 0; $i < @donor; $i ++ ) {
		for ($j = 0; $j < @accept; $j ++ ) {
			@A = split(/\s+/, $peptide[$donor[$i]]);
			@B = split(/\s+/, $peptide[$accept[$j]]);
			if ($A[4] == $B[4]) {
				next;
			}
			push(@pairs, "$A[1]  $B[1]");

			$dist = ($A[5] - $B[5])**2;
			$dist += ($A[6] - $B[6])**2;
			$dist += ($A[7] - $B[7])**2;
			$dist = sqrt($dist);

			if($dist > 3.5) {
				next;
			}
			@H = split(/\s+/, $donorH[$i]);
			for ($k = 0; $k < @H; $k++ ) {
				#print "$peptide[$H[$k]]\n ";
				@C = split (/\s+/, $peptide[$H[$k]]);
				$dist = ($C[5] - $B[5])**2;
				$dist += ($C[6] - $B[6])**2;
				$dist += ($C[7] - $B[7])**2;
				$dist = sqrt($dist);
				if ($dist > 2.5) {
					next;
				}
				#Calculate the Angle between them.
				
				$dist2 = ($C[5] - $A[5])**2;
				$dist2 += ($C[6] - $A[6])**2;
				$dist2 += ($C[7] - $A[7])**2;
				$dist2 = sqrt($dist2);
				
				$theta = ($A[5] - $C[5])*($B[5] - $C[5]);
				$theta += ($A[6] - $C[6])*($B[6] - $C[6]);
				$theta += ($A[7] - $C[7])*($B[7] - $C[7]);
				if ($dist*$dist2 == 0) {
					print "$A[1] $B[1] $C[1]\n";
					exit;
				}
				$theta /= ($dist *$dist2);

				$theta = rad2deg(acos($theta));

				if (abs(180 - $theta) > 30) {
					next;
				}
				#print "$A[1] $C[1] $B[1] $theta\n";
				@bonds[@pairs-1] = 1;
				$nbonds++;
				
				#Classification
				if ($A[2] =~ /{CA|N|C|O}/) {
					#Backbone;
					if($B[2] =~ /{CA|N|C|O}/) {
						$bb ++;
						
					} else {
						$scb ++;
					}
				} else {
					if($B[2] =~ /{CA|N|C|O}/) {
						$scb ++;
						
					} else {
						$scsc ++;
					}
				}

			}


		
		}
	}
	$file =~ s/\.pdb//;
	print "$file\t$nbonds\t$bb\t$scsc\t$scb\n";
	print BD "$file\t@bonds\n";
	
}

sub bond_data
{
	if (@pairs == @bonds ) {
		print "Pairs and Bonds equal\n";
	}

	for ($i = 0; $i < @pairs; $i++) {
		print "\@ s$i legend \"$pairs[$i]\"\n";
		print "\@ s$i hidden true\n";
		print "\@ s$i off\n";
				
	}
	for ($i = 0; $i < @pairs; $i++) {
		$new = @pairs +$i;
		print "\@ sort s$i X ascending\n";
	}
}
