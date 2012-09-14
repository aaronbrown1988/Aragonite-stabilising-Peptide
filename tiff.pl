#!/usr/bin/perl
open(TOP, $ARGV[1]);
open(GMX, $ARGV[0]);
open(OUT, ">peptide.itp");
open(NB, "ffnonbonded.itp");
open(NBOUT, ">ffnonbonded.rest.itp");

# Scaling factor!
$l = $ARGV[2]/$ARGV[3];


# Lets parse the GMXDUMP

#Find functions
while ($line = readline(GMX)) {
	if($line =~ /.*ffparams.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
}
$nf = 0;
while ($line = readline(GMX)) {
	if ($line !~ /.*functype.*/) {
		last;
	}
	push(@functype, $line);
	$nf++;
}

print "Read in $nf function types\n";

#Move to Bonds

while($line = readline(GMX)) {
	if ($line =~ /.*Bond.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
}
$nb = 0;
while ($line = readline(GMX)) {
	$line =~ s/^\s+//;
	if ($line =~ /.*:.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
	@params = split(/\s+/, $line);
	$params[1] =~ s/.+=//;
	$bonds[$params[0]][0] = $params[1];
	$bonds[$params[0]][1] = ++$params[3];
	$bonds[$params[0]][2] = ++$params[4];
	$nb++;

}

#Angles
$na = 0;
while ($line = readline(GMX)) {
	$line =~ s/^\s+//;
	if ($line =~ /.*:.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
	@params = split(/\s+/, $line);
	$params[1] =~ s/.+=//;
	$ub[$params[0]][0] = $params[1];
	$ub[$params[0]][1] = ++$params[3];
	$ub[$params[0]][2] = ++$params[4];
	$ub[$params[0]][3] = ++$params[5];
	$na++;

}

#PDIH
$nd = 0;
while ($line = readline(GMX)) {
	$line =~ s/^\s+//;
	if ($line =~ /.*:.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
	@params = split(/\s+/, $line);
	$params[1] =~ s/.+=//;
	$pd[$params[0]][0] = $params[1];
	$pd[$params[0]][1] = ++$params[3];
	$pd[$params[0]][2] = ++$params[4];
	$pd[$params[0]][3] = ++$params[5];
	$pd[$params[0]][4] = ++$params[6];
	$nd++;

}

#IMP
$ni = 0;
while ($line = readline(GMX)) {
	$line =~ s/^\s+//;
	if ($line =~ /.*:.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
	@params = split(/\s+/, $line);
	$params[1] =~ s/.+=//;
	$id[$params[0]][0] = $params[1];
	$id[$params[0]][1] = ++$params[3];
	$id[$params[0]][2] = ++$params[4];
	$id[$params[0]][3] = ++$params[5];
	$id[$params[0]][4] = ++$params[6];
	$ni++;

}


$nc = 0;
while ($line = readline(GMX)) {
	$line =~ s/^\s+//;
	if ($line =~ /.*:.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
	@params = split(/\s+/, $line);
	$params[1] =~ s/.+=//;
	$cmap[$params[0]][0] = $params[1];
	$cmap[$params[0]][1] = ++$params[3];
	$cmap[$params[0]][2] = ++$params[4];
	$cmap[$params[0]][3] = ++$params[5];
	$cmap[$params[0]][4] = ++$params[6];
	$cmap[$params[0]][5] = ++$params[7];
	$nc++;

}




$np =0;
while ($line = readline (GMX)) {
	$line =~ s/^\s+//;
	if ($line =~ /.*:.*/) {
		$line = readline(GMX);
		$line = readline(GMX);
		last;
	}
	@params = split(/\s+/, $line);
	$params[1] =~ s/.+=//;
	$pair[$params[0]][0] = $params[1];
	$pair[$params[0]][1] = ++$params[3];
	$pair[$params[0]][2] = ++$params[4];
	$np++;

}
	


if ($ARGV[4] == 1) {
	# Fix UB
	for ($i = 0; $i < $na; $i ++) {
		$line = $functype[$ub[$i][0]];
		$line =~ s/^\s+//;
		chomp($line);
		$line =~ s/[A-z0-9]+=//g;
		$line =~ s/[A-Z]+,\s*//;
		@params = split(/,\s*/, $line);
		if ($params[3] != 0) {
			$kb = $params[3] *$l;
			$line="FAKE, b0A= $params[2], cbA= $params[3], b0B= $params[2], cbB= $kb\n";
			push(@functype, $line);
			$bonds[$nb][0] = $nf;
			$bonds[$nb][1] = $ub[$i][1];
			$bonds[$nb][2] = $ub[$i][3];
			$nf++;
			$nb++
		}
	}
$fix = 1;
}


			

#####  Write stuffs!

#Write header ot Tiff's partial itp file

while ($line = readline(TOP)) {
		print OUT $line;



}
#Bonds

print OUT "\n\n[ bonds ]\n";

for($i = 0; $i < $nb; $i++) {
	$line = $functype[$bonds[$i][0]];
	$line =~ s/^\s+//;
	chomp($line);
	$line =~ s/[A-z0-9]+=//g;
	$line =~ s/[A-Z]+,\s*//;
	@params = split(/,\s*/, $line);
	$params[3] *= $l;
	print OUT "$bonds[$i][1]\t$bonds[$i][2]\t1\t@params\n";
#	printf(OUT "%d\t%d\t1\t%10.3lf\t%10.3lf\t%10.3lf\t%10.3lf\n", $bonds[$i][1], $bonds[$i][2],$params[0],$params[1],$params[2],$params[3]);
	
}

print OUT "\n[ pairs ]\n";
for ($i = 0; $i < $np; $i++){
	$line = $functype[$pair[$i][0]];
	chomp($line);
	$line =~ s/^\s+//;
	$line =~ s/[A-z0-9]+=//g;
	$line =~ s/[A-Z_]+,\s*//;
	$line =~ s/LJ14,\s*//;
	@params = split(/,\s*/, $line);
	$params[3] *= $l;
	print OUT "$pair[$i][1]\t$pair[$i][2]\t1\n";#\t@params\n";	
}



#Angles
print OUT "\n[ angles ]\n";

for($i = 0; $i < $na; $i++) {
	$line = $functype[$ub[$i][0]];
	chomp($line);
	$line =~ s/^\s+//;
	$line =~ s/[A-z0-9]+=//g;
	$line =~ s/[A-Z_]+,\s*//;
	@params = split(/,\s*/, $line);
	$kt = $params[1] * $l;
	if ($fix != 1) {
		print OUT "$ub[$i][1]\t$ub[$i][2]\t$ub[$i][3]\t5\t@params\n";
	} else {
		#We're going for scaling these aswell 
		print OUT "$ub[$i][1]\t$ub[$i][2]\t$ub[$i][3]\t1\t$params[0]\t$params[1]\t$params[0]\t$kt\n";
	}
	
}
	
print OUT "\n[ dihedrals ]\n";

for($i = 0; $i < $nd; $i++) {
	$line = $functype[$pd[$i][0]];
	chomp($line);
	$line =~ s/^\s+//;
	$line =~ s/[A-z0-9]+=//g;
	$line =~ s/[A-Z_]+,\s*//;
	@params = split(/,\s*/, $line);
	$params[3] *= $l;
	print OUT "$pd[$i][1]\t$pd[$i][2]\t$pd[$i][3]\t$pd[$i][4]\t9\t$params[0]\t$params[1]\t$params[4]\t$params[2]\t$params[3]\t$params[4]\n";
	
}

print OUT "\n[ dihedrals ]\n";

for($i = 0; $i < $ni; $i++) {
	$line = $functype[$id[$i][0]];
	chomp($line);
	$line =~ s/^\s+//;
	$line =~ s/[A-z0-9]+=//g;
	$line =~ s/[A-Z_]+,\s*//;
	@params = split(/,\s*/, $line);
	$params[3] *= $l;
	print OUT "$id[$i][1]\t$id[$i][2]\t$id[$i][3]\t$id[$i][4]\t2\t$params[0]\t$params[1]\t$params[4]\t$params[2]\t$params[3]\t$params[4]\n";
	
}




# ffnonbonded.itp
while ($line = readline(NB)) {
	if ($line !~ /[\[;]/) {
		last;
	}
	print NBOUT $line;
}
while (length($line) > 3) {
	if ($line =~ /^[#;]/) {
		print NBOUT $line;
		$line = readline (NB);
		next;
	}
	@params = split(/\s+/,$line);
	$params[0] = "$params[0]b";
	$params[3] *= sqrt($l);
	$params[6] *= $l;
	print NBOUT $line;
	print NBOUT "@params\n";
	$line = readline(NB);
}
while ($line = readline(NB)) {
	if ($line !~ /[\[;]/) {
		last;
	}
	print NBOUT $line;
}
while (length($line) > 3) {
	if ($line =~ /^[#;]/) {
		print NBOUT $line;
		$line = readline (NB);
		next;
	}
	@params = split(/\s+/,$line);
	$params[0] = "$params[0]b";
	$params[1] = "$params[1]b";
	$params[4] *= $l;
	print NBOUT $line;
	print NBOUT "@params\n";
	$line = readline (NB);
}
	
