#!/usr/bin/perl
#
# Finds h bonds. Takes a folder of pdb's as the argument.
# Caveat: Peptide must be centered in the box, It's can't be hanging over the PBC
#
use Math::Trig;
my @pairs = qw();
my @surf_pairs = qw();
my @bonds = qw();
my @summary = qw();
my $npairs=-1;
my $has_cht=0;
$folder = $ARGV[0];
#my $sep_chains = ($ARGV[1] == undef)? 0:1
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
#		if ($I >=  2) { last;}
}
closedir(DH);
#bond_data();
bond_sum();
coarse_sum();
BB_sum();
SCSC_sum();
SCB_sum();
HB_table();
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
	my @box = qw(99e99 99e99 99e99);
	my @accept = qw();
	my @donor = qw();
	my @donorH = qw();
	my @peptide = qw();
	my $file = shift;
	open(FH, "$folder/$file") || die "couldn't open $folder/$file :$!\n";
	my @pep_com = qw( 99e99 99e99 99e99);
	my $pep_n = 0;
	while($line = readline(FH)) {
		if ($line =~ /.*CRYST.*/) {
			@params = split(/\s+/, $line);
			$box[0] = $params[1];
			$box[1] = $params[2];
			$box[2] = $params[3];
#			print "$file BOX: $box[0] $box[1] $box[2]\n";
			next;

		}
		if ($line !~ /.*ATOM.*/) {
			next;
		}
		if ($line =~ /.*CHT.*/) {
			next;
		}
		# Multiple chains fix
		@params = split(/\s+/,$line);
		if ($params[4] !~ /[0-9.]+/) {
			$line =~ s/ $params[4] //;
			$line =~ s/$params[3]/$params[3]$params[4]/;
#			print "$line\n";
		}
		@params = split(/\s+/,$line);
	
		$ox = $params[5];
		$oy = $params[6];
		$oz = $params[7];

		# Move us in if were below
		$params[5] = ($params[5] < 0)? ($params[5]+$box[0]):$params[5];
		$params[6] = ($params[6] < 0)? ($params[6]+$box[1]):$params[6];
		$params[7] = ($params[7] < 0)? ($params[7]+$box[2]):$params[7];
		
		#Move us in if were above
		$params[5] = ($params[5] > $box[0])? ($params[5]-$box[0]):$params[5];
		$params[6] = ($params[6] > $box[1])? ($params[6]-$box[1]):$params[6];
		$params[7] = ($params[7] > $box[2])? ($params[7]-$box[2]):$params[7];
			
		$line =~ s/$ox/$params[5]/;
		$line =~ s/$oy/$params[6]/;
		$line =~ s/$oz/$params[7]/;
		
		@params = split(/\s+/,$line);

		$pep_com[0] = ($params[5] < $pep_com[0])? $params[5]:$pep_com[0];
		$pep_com[1] = ($params[6] < $pep_com[1])? $params[6]:$pep_com[1];
		$pep_com[2] = ($params[7] < $pep_com[2])? $params[7]:$pep_com[2];
		push(@peptide, $line);
	}
	seek(FH,0, SEEK_SET);
	while ($line = readline(FH)) {
		if($line !~ /.*ATOM.*/) {
			next;
		}
		if ($line !~ /.*CHT.*/) {
			$has_cht=1;
			next;
		}
		@params = split(/\s+/,$line);
		if ($params[4] !~ /[0-9.]+/) {
			$line =~ s/ $params[4] //;
#			$line =~ s/$params[3]/$params[3]]/;
#			print "$line\n";
		}
		$ox = $params[5];
		$oy = $params[6];
		$oz = $params[7];
		# Move us in if were below
		$params[5] = ($params[5] < 0)? ($params[5]+$box[0]):$params[5];
		$params[6] = ($params[6] < 0)? ($params[6]+$box[1]):$params[6];
		$params[7] = ($params[7] < 0)? ($params[7]+$box[2]):$params[7];
		
		#Move us in if were above
		$params[5] = ($params[5] > $box[0])? ($params[5]-$box[0]):$params[5];
		$params[6] = ($params[6] > $box[1])? ($params[6]-$box[1]):$params[6];
		$params[7] = ($params[7] > $box[2])? ($params[7]-$box[2]):$params[7];
		
		$line =~ s/$ox/$params[5]/;
		$line =~ s/$oy/$params[6]/;
		$line =~ s/$oz/$params[7]/;
		
		@params = split(/\s+/,$line);
		@params = split(/\s+/,$line);
		if ( abs($params[5] - $pep_com[0]) > 6) {
			#skip if the position of the chitin is more than
			# 20 from COM of peptide
			next;
		}
		push(@peptide, $line);
	}
	close(FH);
	
	#Look for suitable Heavy Atoms
	for ($i = 0; $i < @peptide; $i++) {
		$line = $peptide[$i];
		@params = split (/\s+/, $line);
		if ($params[2] !~ /^[FOSN].*/) {
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
			} elsif ($params2[2] !~ /^[12]*H[HNGTZDE123]*.*/) {
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

	#print "D:@donor\nA:@accept\nH:@donorH\n";
	#loop through donors
	$nbonds = 0;
	$scsc = 0;
	$bb = 0;
	$scb = 0;
	@pairs = qw();
	@surf_pairs = qw();
	@bonds = qw();
	print BD "$file"; 
	for ($i = 0; $i < @donor; $i ++ ) {
		for ($j = 0; $j < @accept; $j ++ ) {
			@A = split(/\s+/, $peptide[$donor[$i]]);
			@B = split(/\s+/, $peptide[$accept[$j]]);
			if ($A[4] == $B[4]) {
				next;
			}
			if ($peptide[$donor[$i]] =~ /.*CHT.*/ && $peptide[$accept[$j]] =~ /.*CHT.*/) {
				next;
			}

			if($A[3] !~ /CHT/ && $B[3] !~/CHT/) {
				push(@pairs, "$A[3]$A[4]:$A[2]  $B[3]$B[4]:$B[2]");
			} else {
				push(@surf_pairs, "$A[3]$A[4]:$A[2]  $B[3]$B[4]:$B[2]");
			}

			$bonds[@pairs-1] = 0;
			
			$dx = (($A[5] - $B[5])**2)**0.5;
			$dy = (($A[6] - $B[6])**2)**0.5;
			$dz = (($A[7] - $B[7])**2)**0.5;

			if(($dx > (0.5*$box[0])) && ($A[5] > $B[5])) {
				$B[5] += $box[0];
			}elsif (($dx > (0.5*$box[0])) && ($A[5] < $B[5])) {
				$A[5] += $box[0];
			}
			if(($dy > (0.5*$box[1])) && ($A[6] > $B[6])) {
				$B[6] += $box[1];
			}elsif (($dy > (0.5*$box[1])) && ($A[6] < $B[6])) {
				$A[6] += $box[1];
			}
			if(($dz > (0.5*$box[2])) && ($A[7] > $B[7])) {
				$B[7] += $box[2];
			}elsif (($dz > (0.5*$box[2])) && ($A[7] < $B[7])) {
				$A[7] += $box[2];
			}
			
			
			
			if ($dx > (0.5*$box[0])) { $dx -= (0.5*$box[0]);}
			if ($dy > (0.5*$box[1])) { $dy -= (0.5*$box[1]);}
			if ($dz > (0.5*$box[2])) { $dz -= (0.5*$box[2]);}



			$dist = ($dx)**2;
			$dist += ($dy)**2;
			$dist += ($dz)**2;
			$dist = sqrt($dist);

#			print "$file: $A[3]:$A[2] $B[3]:$B[2] $dist\n";
			if($dist > 3.5) {
				next;
			}
			@H = split(/\s+/, $donorH[$i]);
			for ($k = 0; $k < @H; $k++ ) {
				#print "$peptide[$H[$k]]\n ";
				@C = split (/\s+/, $peptide[$H[$k]]);
				
				$dx = $C[5] -$B[5];
				if (abs($dx) > 0.5*$box[0]) {
					$C[5] += 0.5*$box[0];
				}
				$dy = $C[6] -$B[6];
				if (abs($dy) > 0.5*$box[1]) {
					$C[6] += 0.5*$box[1];
				}
				$dz = $C[7] -$B[7];
				if (abs($dx) > 0.5*$box[2]) {
					$C[7] += 0.5*$box[2];
				}


				$dist = ($C[5] - $B[5])**2;
				$dist += ($C[6] - $B[6])**2;
				$dist += ($C[7] - $B[7])**2;
				$dist = sqrt($dist);
#				print "$file:$C[2] $B[2] $dist\n";
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
#				print "$file $A[2] $B[2] $C[2] theta: $theta\n";

				if (abs(180 - $theta) > 30) {
					next;
				}
#				print "$file $A[2] $B[2] $C[2] - pass\n";
				if (($A[2] !~ /(CA|N|C|O|NT)\b/ && $B[2] !~ /(CA|C|N|O|NT)\b/) && (($A[3] =~ /(ASP|GLU)/ && $B[3] =~ /(LYS|ARG)/) || ($B[3] =~ /(ASP|GLU)/ && $A[3] =~ /(LYS|ARG)/)) ) {
					next;
				}
				#print "$A[1] $C[1] $B[1] $theta\n";
				@bonds[@pairs-1] = -1;
				$summary[@pairs-1]++;
				$nbonds++;
				
				if ($has_cht==1 && ($A[3] =~ /.*CHT.*/ || $B[3] =~ /.*CHT.*/)) {
					if ($A[3] =~ /.*CHT.*/) {
						print BD ",CHT$A[4]:$A[2]-$B[3]$B[4]:$B[2]";
					} elsif ($B[3] =~ /.*CHT.*/) {
						print BD ",CHT$B[4]:$B[2]-$A[3]$A[4]:$A[2]";
					}
						
				} else {	
				#Classification
					if ($A[2] =~ /(CA|N|C|O|NT)\b/) {
						#Backbone;
						if($B[2] =~ /(CA|N|C|O|NT)\b/) {
							$bb ++;
							
						} else {
							$scb ++;
						}
					} else {
						if($B[2] =~ /(CA|N|C|O|NT)\b/) {
							$scb ++;
							
						} else {
						
								$scsc ++;
						}
					}
					print BD ",$A[3]$A[4]:$A[2]-$B[3]$B[4]:$B[2]";
				}

			}


		
		}
	}
	$file =~ s/\.pdb//;
	 $npairs = ($npairs==-1)? scalar(@pairs): $npairs;

	$throw = scalar(@pairs);
#	print "$throw =? $npairs\n";
	 if ($npairs != scalar(@pairs)) {
	#	 die "had $npairs now have $throw\n";
		 print STDERR "$file has $throw peptide pairs instead of $npairs we started with\n";
		#set npairs to the lowest value.
		# this is because for the latter output we want just the peptide/peptide counted	
		 $npairs = ($npairs > $throw)? $throw:$npairs;
		 
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

sub coarse_sum
{
	open (CS, ">HB_res_sum.txt") || die "Couldn't open HB_sum for writing\n";
	printf CS "%10s\t%10s\t%10s\t%10s\n", "Res1","Res2","Occurance","% of frames";
	print CS "--------------------------------------------------------------------------\n";
	my %sum;
	for ($i = 0; $i < @pairs; $i++) {
		@throw = split(/[:-\s]+/, $pairs[$i]);
		#Check to see if SCSC Charge residue and bail
		if ( ( ($throw[2] =~ /ASP.*/ || $throw[2] =~ /GLU.*/) && ($throw[0] =~  /LYS.*/ || $throw[0] =~ /ARG.*/)) || ( ($throw[0] =~ /ASP.*/ || $throw[0] eq /GLU.*/) && ($throw[2] =~  /LYS.*/ || $throw[2] =~ /ARG.*/) ) ) {
			if ($throw[1] !~ /(CA|N|C|O|NT)\b/ && $throw[3] !~ /(CA|N|C|O|NT)\b/) {
				next;
			}
		}

		$throw[1] = $throw[0];
		$throw[3] = $throw[2];
		$throw[1] =~ s/[A-Z]{3}//;
		$throw[3] =~ s/[A-Z]{3}//;
		
		$chain[0] = $throw[1];
		$chain[1] = $throw[3];
		$chain[0] =~ s/[0-9]+//;
		$chain[1] =~ s/[0-9]+//;

		$throw[1] =~ s/[A-Z]+//;
		$throw[3] =~ s/[A-Z]+//;
		if ($chain[0] eq $chain[1]) {
			if ($throw[1] <= $throw[3]) {
				$line = "$throw[0] $throw[2]";
			} else {
				$line = "$throw[2] $throw[0]";
			}
		}elsif ($chain[0] > $chain[1])  {
			$line = "$throw[2] $throw[0]";
		} else {
			$line = "$throw[0] $throw[2]";
		}

#		print STDERR "$pairs[$i]: @throw = $line $summary[$i]\n";
		$sum{$line} += $summary[$i];
	}
	@sum_pairs = sort { $sum{$b} <=> $sum{$a} } keys %sum;
	for ($i = 0; $i < @sum_pairs; $i++) {
		$line = $sum_pairs[$i];#$sum{$summary[$i]};
		@params = split(/\s+/, $line);
		$percent = $sum{$sum_pairs[$i]} / scalar(@files) * 100;
		printf CS "%10s\t%10s\t%10s\t\%3.2f\n", $params[0],$params[1],$sum{$sum_pairs[$i]}, $percent;

	}
	close(CS);
}

sub bond_sum
{
	open(BS, ">HB_sum.txt" ) || die "Couldn't open HB_sum for writing\n";
	printf CBS "%10s\t%10s\t%10s\t%10s\n", "Atom","Atom2","Occurance","% of frames";
	print BS "--------------------------------------------------------------------------\n";
	my %sum;
	for ($i = 0; $i < @pairs; $i++) {
		$sum{$pairs[$i]} = $summary[$i];
	}
	@sum_pairs = sort { $sum{$b} <=> $sum{$a} } keys %sum;
	for ($i = 0; $i < @pairs; $i++) {
		$line = $sum_pairs[$i];#$sum{$summary[$i]};
		@params = split(/\s+/, $line);
		$percent = $sum{$sum_pairs[$i]} / scalar(@files);
		printf BS "%10s\t%10s\t%10s\t\%3.2f\n", $params[0],$params[1],$sum{$sum_pairs[$i]}, $percent;

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
		if (($params[1] =~ /(CA|N|C|O|NT)\b/) && ($params[3] =~ /(CA|C|N|O|NT)\b/)) {
			$params[1] = $params[0];
			$params[3] = $params[2];
			$params[1] =~ s/[A-Z]{3}//;
			$params[3] =~ s/[A-Z]{3}//;
		
			$chain[0] = $params[1];
			$chain[1] = $params[3];
			$chain[0] =~ s/[0-9]+//;
			$chain[1] =~ s/[0-9]+//;

			$params[1] =~ s/[A-Z]+//;
			$params[3] =~ s/[A-Z]+//;
			if ($chain[0] eq $chain[1]) {
				if ($params[1] <= $params[3]) {
					$line = "$params[0] $params[2]";
				} else {
					$line = "$params[2] $params[0]";
				}
			}elsif ($chain[0] > $chain[1])  {
				$line = "$params[2] $params[0]";
			} else {
				$line = "$params[0] $params[2]";
			}
			if( $sum{$line} == undef) {
				 $sum{$line} = 0;
			}
			$sum{$line} += $summary[$i];
			push(@BB_pairs, $line);
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
		if ($params[1] !~ /(CA|N|C|O|NT)\b/ && $params[3] !~ /(CA|C|N|O|NT)\b/) {
			if ( ($params[0] =~ /(ASP|GLU).*/ && $params[3] =~ /(ARG|LYS).*/) || ($params[3] =~ /(ASP|GLU).*/ && $params[0] =~ /(ARG|LYS).*/)) {
				next;
			}
			$params[1] = $params[0];
			$params[3] = $params[2];
			$params[1] =~ s/[A-Z]{3}//;
			$params[3] =~ s/[A-Z]{3}//;
		
			$chain[0] = $params[1];
			$chain[1] = $params[3];
			$chain[0] =~ s/[0-9]+//;
			$chain[1] =~ s/[0-9]+//;

			$params[1] =~ s/[A-Z]+//;
			$params[3] =~ s/[A-Z]+//;
			if ($chain[0] eq $chain[1]) {
				if ($params[1] <= $params[3]) {
					$line = "$params[0] $params[2]";
				} else {
					$line = "$params[2] $params[0]";
				}
			}elsif ($chain[0] > $chain[1])  {
				$line = "$params[2] $params[0]";
			} else {
				$line = "$params[0] $params[2]";
			}
			$sum{$line} += $summary[$i];
			push(@SCSC_pairs, $line);
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

		if (($params[1] =~ /^(CA|N|C|O|NT)\b/ && ($params[3] !~ /^(CA|C|N|O|NT)\b/)) || (($params[3] =~ /(CA|C|N|O|NT)\b/) && ($params[1] !~ /(CA|C|N|O|NT)\b/))) {
			$params[1] = $params[0];
			$params[3] = $params[2];
			$params[1] =~ s/[A-Z]{3}//;
			$params[3] =~ s/[A-Z]{3}//;
		
			$chain[0] = $params[1];
			$chain[1] = $params[3];
			$chain[0] =~ s/[0-9]+//;
			$chain[1] =~ s/[0-9]+//;

			$params[1] =~ s/[A-Z]+//;
			$params[3] =~ s/[A-Z]+//;
			if ($chain[0] eq $chain[1]) {
				if ($params[1] <= $params[3]) {
					$line = "$params[0] $params[2]";
				} else {
					$line = "$params[2] $params[0]";
				}
			}elsif ($chain[0] > $chain[1])  {
				$line = "$params[2] $params[0]";
			} else {
				$line = "$params[0] $params[2]";
			}
			$sum{$line} += $summary[$i];
			push(@SCB_pairs, $line);
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


sub HB_table
{
	open(TAB, ">table.tex" ) || die " Couldn't open table.tex for writing";
	print TAB "\\begin\{tabular\}\{l|c|c|c|c|c\}\n";
	print TAB " Residue & total & BB & SB && SS \\\\\n";
	my %SCB_pairs;
	my %total_pairs;
	my %BB_pairs;
	my %SCSC_pairs;
	my @total;
	for ($i = 0; $i < @pairs; $i++) {
		@params = split(/[:-\s]+/, $pairs[$i]);
		$tmp[1] = $params[0];
		$tmp[3] = $params[2];
		$tmp[1] =~ s/[A-Z]{3}//;
		$tmp[3] =~ s/[A-Z]{3}//;
	
		$chain[0] = $tmp[1];
		$chain[1] = $tmp[3];
		$chain[0] =~ s/[0-9]+//;
		$chain[1] =~ s/[0-9]+//;
		$tmp[1] =~ s/[A-Z]+//;
		$tmp[3] =~ s/[A-Z]+//;
		
		# Keep the chains the right way round
		if ($chain[0] eq $chain[1]) {
			#Same chain Sort by residue
			if ($tmp[1] <= $tmp[3]) {
				$line = "$params[0] $params[2]";
			} else {
				$line = "$params[2] $params[0]";
			}
		} elsif ($chain[0] > $chain[1])  {
			$line = "$params[2] $params[0]";
		} else {
			$line = "$params[0] $params[2]";
		}
		$total_pairs{$line} += $summary[$i];
		push(@total,$line);
		#Determine Type
		if ($params[1] =~ /(CA|N|C|O|NT)\b/) {
			#Backbone;
			if($params[3] =~ /(CA|N|C|O|NT)\b/) {
				$BB_pairs{$line} += $summary[$i];	
				
			} else {
				$SCB_pairs{$line} += $summary[$i];
			}
		} else {
			if($params[3] =~ /(CA|N|C|O|NT)\b/) {
				$SCB_pairs{$line} += $summary[$i];
		
			} else {
				$SCSC_pairs{$line} += $summary[$i];
			}
		}
	}
	
	for ($i = 0; $i < @total; $i++) {
		
	}

	@total = sort{ $total_pairs{$b} <=> $total_pairs{$a} } keys %total_pairs;
	for ($i = 0; $i < @total; $i++) {
		$a = $total[$i];
		$total_pairs{$a} /= (scalar(@files)/100);
		$BB_pairs{$a} /= (scalar(@files)/100);
		$SCB_pairs{$a} /= (scalar(@files)/100);
		$SCSC_pairs{$a} /= (scalar(@files)/100);
		printf TAB "%s & %2.2f & %2.2f & %2.2f & %2.2f \\\\\n" ,$total[$i] , $total_pairs{$a} , $BB_pairs{$a} , $SCB_pairs{$a} , $SCSC_pairs{$a};
	}

	print TAB '\end{tabular}';
	print TAB "\n";
	
	close(TAB);



}	



