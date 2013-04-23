#!/usr/bin/perl
#
# Finds h bonds. Takes a folder of pdb's as the argument.
#
use Math::Trig;
my @pairs = qw();
my @bonds = qw();
my @summary = qw();
my $npairs=-1;
$folder = $ARGV[0];
opendir(DH, "$ARGV[0]") || die "couldn't open $ARGV[0]: $!\n";
open(BD, ">Bond_data.dat");
while ($file = readdir(DH)) {
	if ($file =~ /.*\.pdb/ && $file !~ /.pdb.+/) {
		push(@files,$file);
	}
}
@files = sort { $a <=> $b } @files;
for($I=0; $I < @files; $I++) {
		$file = $files[$I];
		process($file);
	#		if ($file >=  100) { last;}
#		last;
		#exit;
}
closedir(DH);
#bond_data();
bond_sum();
BB_sum();
SCSC_sum();
SCB_sum();
print <<END;
@ s0 legend "# bonds"
@ s0 hidden false
@ s0 on
@ s1 legend "# BB bonds"
@ s1 hidden false
@ s1 on
@ s2 legend "# SC-SC bonds"
@ s2 hidden false
@ s2 on
@ s3 legend "# SC-BB bonds"
@ s3 hidden false
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
	my $file = shift;
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
		if ($params[2] !~ /^[FON].*/) {
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
			} elsif ($params2[2] !~ /^[12]*H[HNTZDE123].*/) {
				last;
			}
			#Calculate the distance to the H
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
		push(@accept, "$i");

	}

	print "D:@donor\nA:@accept\nH:@donorH\n";
	#loop through donors
	$nbonds = 0;
	$scsc = 0;
	$bb = 0;
	$scb = 0;
	@pairs = qw();
	@bonds = qw();
	print BD "$file"; 
	for ($i = 0; $i < @donor; $i ++ ) {
		for ($j = 0; $j < @accept; $j ++ ) {
			@A = split(/\s+/, $peptide[$donor[$i]]);
			@B = split(/\s+/, $peptide[$accept[$j]]);
			if ($A[4] == $B[4]) {
				next;
			}
			push(@pairs, "$A[3]$A[4]:$A[2]  $B[3]$B[4]:$B[2]");
			$bonds[@pairs-1] = 0;
			$dist = ($A[5] - $B[5])**2;
			$dist += ($A[6] - $B[6])**2;
			$dist += ($A[7] - $B[7])**2;
			$dist = sqrt($dist);

			#print "$A[1] $B[1] $dist\n";
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
					#print "$A[1] $B[1] $C[1]\n";
					exit;
				}
				$theta /= ($dist *$dist2);

				$theta = rad2deg(acos($theta));

				if (abs(180 - $theta) > 30) {
					next;
				}
				#print "$A[1] $C[1] $B[1] $theta\n";
				@bonds[@pairs-1] = -1;
				$summary[@pairs-1]++;
				$nbonds++;
				
				
				#Classification
				if ($A[2] =~ /(CA|N|C|O)\b/) {
					#Backbone;
					if($B[2] =~ /(CA|N|C|O)\b/) {
						$bb ++;
						
					} else {
						$scb ++;
					}
				} else {
					if($B[2] =~ /(CA|N|C|O)\b/) {
						$scb ++;
						
					} else {
						$scsc ++;
					}
				}
				print BD ",$A[3]$A[4]:$A[2]-$B[3]$B[4]:$B[2]";

			}


		
		}
	}
	$file =~ s/\.pdb//;
	 $npairs = ($npairs==-1)? scalar(@pairs): $npairs;

	$throw = scalar(@pairs);
#	print "$throw =? $npairs\n";
	 if ($npairs != scalar(@pairs)) {
		 die "had $npairs now have $throw\n";
	 }
		
	print "$file\t$nbonds\t$bb\t$scsc\t$scb\n";
	print BD "\n";
	
}

sub bond_data
{
	if (@pairs == @bonds ) {
		print "Pairs and Bonds equal\n";
	}

	for ($i = 0; $i < @pairs; $i++) {
		print BD "\@ s$i legend \"$pairs[$i]\"\n";
		print BD "\@ s$i hidden false\n";
		print BD "\@ s$i on\n";
		print BD "\@ s$i symbol 1\n";
				
	}
	for ($i = 0; $i < @pairs; $i++) {
		$new = @pairs +$i;
		print BD "\@ sort s$i X ascending\n";
	}
}

sub bond_sum
{
	open (BS, ">HB_sum.txt") || die "Couldn't open HB_sum for writing\n";
	printf BS "%10s\t%10s\t%10s\t%10s\n", "Atom1","Atom2","Occurance","% of frames";
	print BS "--------------------------------------------------------------------------\n";
	my %sum;
	for ($i = 0; $i < @pairs; $i++) {
		$sum{$pairs[$i]} = $summary[$i];
	}
	@pairs = sort { $sum{$b} <=> $sum{$a} } keys %sum;
	for ($i = 0; $i < @pairs; $i++) {
		$line = $pairs[$i];#$sum{$summary[$i]};
		@params = split(/\s+/, $line);
		$percent = $sum{$pairs[$i]} / scalar(@files);
		printf BS "%10s\t%10s\t%10s\t\%3.2f\n", $params[0],$params[1],$sum{$pairs[$i]}, $percent;

	}
	close(BS);
}

sub BB_sum
{

	open(BB, ">BB.tsv") || die "Couldn't open BB.txt\n";
	printf BB "#%10s\t%10s\t%10s\n", "Atom1","Atom2","Occurance";
	print BB "#--------------------------------------------------------------------------\n";
	my @BB_pairs;
	my %sum;
	for ($i = 0; $i < @pairs; $i++) {
		@params = split(/[: -]+/, $pairs[$i]);
		if ($params[1] =~ /(CA|N|C|O)\b/ && $params[3] =~ /(CA|C|N|O)\b/) {
			$sum{"$params[0] $params[2]"} += $summary[$i];
			push(@BB_pairs, "$params[0] $params[2]");
		}

	}



	@BB_pairs = sort { $sum{$b} <=> $sum{$a} } keys %sum;
	for ($i = 0; $i < @BB_pairs; $i++) {
		$line = $BB_pairs[$i];#$sum{$summary[$i]};
		@params = split(/\s+/, $line);
		printf BB "%10s\t%10s\t%10s\n", $params[0],$params[1],$sum{$BB_pairs[$i]} ;

	}
	close(BB);

}
sub SCSC_sum
{

	open(SCSC, ">SCSC.tsv") || die "Couldn't open SCSC.txt\n";
	printf SCSC "#%10s\t%10s\t%10s\n", "Atom1","Atom2","Occurance";
	print SCSC "#--------------------------------------------------------------------------\n";
	my @SCSC_pairs;
	my %sum;
	for ($i = 0; $i < @pairs; $i++) {
		@params = split(/[: -]+/, $pairs[$i]);
		if ($params[1] !~ /(CA|N|C|O)\b/ && $params[3] !~ /(CA|C|N|O)\b/) {
			$sum{"$params[0] $params[2]"} += $summary[$i];
			push(@SCSC_pairs, "$params[0] $params[2]");
		}

	}



	@SCSC_pairs = sort { $sum{$b} <=> $sum{$a} } keys %sum;
	for ($i = 0; $i < @SCSC_pairs; $i++) {
		$line = $SCSC_pairs[$i];#$sum{$summary[$i]};
		@params = split(/\s+/, $line);
		printf SCSC "%10s\t%10s\t%10s\n", $params[0],$params[1],$sum{$SCSC_pairs[$i]};

	}
	close(SCSC);

}
sub SCB_sum
{

	open(SCB, ">SCB.tsv") || die "Couldn't open SCB.txt\n";
	printf SCB "#%10s\t%10s\t%10s\n", "Atom1","Atom2","Occurance";
	print SCB "#--------------------------------------------------------------------------\n";
	my @SCB_pairs;
	my %sum;
	for ($i = 0; $i < @pairs; $i++) {
		@params = split(/[: -]+/, $pairs[$i]);
		if ($params[1] =~ /(CA|N|C|O)\b/ || $params[3] =~ /(CA|C|N|O)\b/) {
			$sum{"$params[0] $params[2]"} += $summary[$i];
			push(@SCB_pairs, "$params[0] $params[2]");
		}

	}



	@SCB_pairs = sort { $sum{$b} <=> $sum{$a} } keys %sum;
	for ($i = 0; $i < @SCB_pairs; $i++) {
		$line = $SCB_pairs[$i];#$sum{$summary[$i]};
		@params = split(/\s+/, $line);
		printf SCB "%10s\t%10s\t%10s\n", $params[0],$params[1],$sum{$SCB_pairs[$i]};

	}
	close(SCB);

}
