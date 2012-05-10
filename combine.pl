#!/usr/bin/perl

#
# Surface Amino merge
#

print "usage amino.lmp surf.sol.lmp amino.inp surf.inp\n";
open(ALMP, $ARGV[0]);
open(AINP, $ARGV[2]);
open(SLMP, $ARGV[1]);
open(SINP, $ARGV[3]);

open (OINP, ">comb.inp");
open (OLMP, ">comp.lmp");
open (PINP, ">plumed.inp");

# Parse Slab LMP for the bits we care about

while ($line = readline(SLMP)) {
	if ($line =~ /.*bond types.*/) {
		$btoff = $line;
		$btoff =~ s/\s.*//;
	}
	if ($line =~ /.*atom types.*/) {
		$atoff = $line;
		$atoff =~ s/\s.*//;
	}
	if ($line =~ /.*angle types.*/) {
		$antoff = $line;
		$antoff =~ s/\s.*//;
	}
	if ($line =~ /.*improper types.*/) {
		$imptoff = $line;
		$imptoff =~ s/\s.*//;
	}
	if ($line =~ /.*dihedral types.*/) {
		$ditoff = $line;
		$ditoff =~ s/\s.*//;
	}

	if ($line =~ /xlo/) {
		@params = split(/\s+/, $line);
		$wcent[0] = ($params[1] - $params[0])/2;
	}
	if ($line =~ /ylo/) {
		@params = split(/\s+/, $line);
		$wcent[1] = ($params[1] - $params[0])/2;
	}
	if ($line =~ /zlo/) {
		@params = split(/\s+/, $line);
		$wcent[2] = ($params[1] - $params[0])/2;
	}
	
		
}


print OLMP "LAMMPS Description\n\n";


while ( $line = readline(ALMP) ) {
	if ($line =~ /.*bond types.*/) {
		@params = split(/\s+/, $line);
		$params[0] += $btoff;
		print OLMP "@params\n";
	}elsif ($line =~ /.*atom types.*/) {
		@params = split(/\s+/, $line);
		$params[0] += $atoff;
		print OLMP "@params\n";
	}elsif ($line =~ /.*angle types.*/) {
		@params = split(/\s+/, $line);
		$params[0] += $antoff;
		print OLMP "@params\n";
	}elsif ($line =~ /.*improper types.*/) {
		@params = split(/\s+/, $line);
		$params[0] += 1;
		print OLMP "@params\n";
	}elsif ($line =~ /.*dihedral types.*/) {
		@params = split(/\s+/, $line);
		$params[0] += $ditoff;
		print OLMP "@params\n";
	} elsif ($line =~ /xlo/) {
		$params[0] = $wcent[0] * 2;
		print OLMP "\n0.0 $params[0] xlo xhi\n";
	}elsif ($line =~ /ylo/) {
		$params[0] = $wcent[1] * 2;
		print OLMP "0.0 $params[0] ylo yhi\n";
	} elsif ($line =~ /zlo/) {
		$params[0] = $wcent[2] * 2;
		print OLMP "0.0 $params[0] zlo zhi\n";
	} 
	if ( $line =~ /.*Atoms.*/) {
		$line = readline(ALMP);
		last;
	}
}


$xmax = -9999999;
$ymax = $xmax;
$zmax = $xmax;
$xmin = - $xmax;
$ymin = - $xmax;
$zmin = - $xmax;

#Read in atom coordinates to work out centre
while ($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/^\s+//;
	$line =~ s/#.*//;
	@params = split(/\s+/, $line);
	$xmax = ($params[4] > $xmax)? $params[4]: $xmax;
	$ymax = ($params[5] > $ymax)? $params[5]: $ymax;
	$zmax = ($params[6] > $zmax)? $params[6]: $zmax;
	
	$xmin = ($params[4] < $xmin)? $params[4]: $xmin;
	$ymin = ($params[5] < $ymin)? $params[5]: $ymun;
	$zmin = ($params[6] < $zmin)? $params[6]: $zmin;
	
}

#Amino acid centre
$acent[0] = ($xmax - $xmin)/5;
$acent[1] = ($ymax - $ymin)/5;
$acent[2] = ($zmax - $zmin)/5;



#Calulate translation required to move the box.
$offset[0] = $wcent[0] - $acent[0];
$offset[1] = $wcent[1] - $acent[1];
$offset[2] = $wcent[2] - $acent[2];


#Reset Slab + amino acid data files
seek SLMP, 0, SEEK_SET;
seek ALMP, 0, SEEK_SET;



while ( $line = readline(SLMP) ) {
	if ( $line =~ /.*Masses.*/) {
		$line = readline(SLMP);
		last;
	}
}

while ( $line = readline(ALMP) ) {
	if ( $line =~ /.*Masses.*/) {
		print OLMP "\n$line\n";
		$line = readline(ALMP);
		last;
	}
}

while ($line = readline(SLMP)) {
	if (length($line) < 3 ) {
		last;
	}
	print OLMP "$line";
}
while ($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$params[0] += 5;
	print OLMP "\t$params[0]\t$params[1]\t$params[2]\t$params[3]\n";
}






# Output Atoms + Bonds and stuff




#Seek to atoms

while ( $line = readline(SLMP) ) {
	if ( $line =~ /.*Atoms.*/) {
		$line = readline(SLMP);
		last;
	}
}

while ( $line = readline(ALMP) ) {
	if ( $line =~ /.*Atoms.*/) {
		print OLMP "\n$line\n";
		$line = readline(ALMP);
		last;
	}
}

#Read through atoms verbatim and copy into output file.
while ($line = readline(SLMP)) {
	if (length($line)< 3) {
		last;
	}
	print OLMP "$line";
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$atnum = $params[0];
	$molnum = $params[1];
}

# Need to move to atoms section

#Read through atoms in amino adding them to the output file
while($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	
	$line =~ s/\s+//;
	@params = split (/\s+/, $line);
	#Id number offsets;
	$params[0] += $atnum;
	$params[1] += $molnum;
	$params[2] += 5; # Offset atom types (Magic number is from DQ input)
	# Offset atom coordinates
	$params[4] += $offset[0];
	$params[5] += $offset[1];
	$params[6] += $offset[2]; 
	print OLMP "\t$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\t$params[5]\t$params[6]\n";
}

print "$params[0] \n";

#Move both files to the bonds sections

while ( $line = readline(SLMP) ) {
	if ( $line =~ /.*Bonds.*/) {
		print OLMP "\n$line\n";
		$line = readline(SLMP);
		last;
	}
}

while ( $line = readline(ALMP) ) {
	if ( $line =~ /.*Bonds.*/) {
		$line = readline(ALMP);
		last;
	}
}

#Read through the bonds section of slab copying them verbtim
while ($line = readline(SLMP)) {
	if (length($line) < 3) {
		last;
	}
	print OLMP "$line";
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$bnum = $params[0];
}

#Go through the bonds section of the amino acid bumping up bond number and type.
while($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/\s+//;
	@params = split(/\s+/, $line);
	$params[0] += $bnum;
	$params[1] += 2; # Magic number from dq input file
	#Suffle on the atom numbers
	$params[2] += $atnum;
	$params[3] += $atnum;
	print OLMP "\t$params[0]\t$params[1]\t$params[2]\t$params[3]\n";
}

print "$params[0] \n";


#Move both files to the Angles sections

while ( $line = readline(SLMP) ) {
	if ( $line =~ /.*Angles.*/) {
		print OLMP "\n$line\n";
		$line = readline(SLMP);
		last;
	}
}

while ( $line = readline(ALMP) ) {
	if ( $line =~ /.*Angles.*/) {
		$line = readline(ALMP);
		last;
	}
}
#Copy angles from slab verbatim
while ($line = readline(SLMP)) {
	if (length($line) < 3) {
		last;
	}
	print OLMP "$line";
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$annum = $params[0];
} 

#Copy from amino acid bumping number, type and atom number as we go
while($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/\s+//;
	@params = split(/\s+/, $line);
	$params[0] += $annum;
	$params[1] += 2; # Magic number from dq input file
	#Suffle on the atom numbers
	$params[2] += $atnum;
	$params[3] += $atnum;
	$params[4] += $atnum;
	print OLMP "\t$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\n";
}

print "$params[0] \n";

#Cpy Dihedrals as is, given that there shouldn't be any in the slab

##Move to dihedrals

while ( $line = readline(SLMP) ) {
	if ( $line =~ /.*Dihedrals.*/) {
		$line = readline(SLMP);
		last;
	}
}

while ( $line = readline(ALMP) ) {
	if ( $line =~ /.*Dihedrals.*/) {
		print OLMP "\n$line\n";
		$line = readline(ALMP);
		last;
	}
}
#Copy them
while($line = readline(SLMP)) {
	if (length($line) < 3) {
		last;
	}
	print OLMP $line;
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$impnum = $params[0];
}

while($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/\s+//;
	@params = split(/\s+/, $line);
#	$params[0] += $impnum;
#	$params[1] += 1; # Magic number from dq input file
	#Suffle on the atom numbers
	$params[2] += $atnum;
	$params[3] += $atnum;
	$params[4] += $atnum;
	$params[5] += $atnum;
	print OLMP "\t$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\t$params[5]\n";
}

print "$params[0] \n";


#Move to Impropers
seek SLMP, 0, SEEK_SET;
while ( $line = readline(SLMP) ) {
	if ( $line =~ /.*Impropers.*/) {
		print OLMP "\n$line\n";
		$line = readline(SLMP);
		last;
	}
}

while ( $line = readline(ALMP) ) {
	if ( $line =~ /.*Impropers.*/) {
		$line = readline(ALMP);
		last;
	}
}
#Copy them
while($line = readline(SLMP)) {
	if (length($line) < 3) {
		last;
	}
	print OLMP "$line";
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$impnum = $params[0];
}

while($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/\s+//;
	@params = split(/\s+/, $line);
	$params[0] += $impnum;
	$params[1] += 1; # Magic number from dq input file
	#Suffle on the atom numbers
	$params[2] += $atnum;
	$params[3] += $atnum;
	$params[4] += $atnum;
	$params[5] += $atnum;
	print OLMP "\t$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\t$params[5]\n";
}

print "$params[0] \n";


# Now to work out how to past bits into the inp file.....
while ($line = readline(SINP)) {
	print OINP "$line";
	if ($line =~ /.*bond_coeff.*/) {
		last;
	}
}
seek ALMP, 0, SEEK_SET;
while ($line = readline(ALMP)) {
	if ($line =~ /Bond Coeff.*/) {
		$line = readline(ALMP);
		last;
	}
}
while ($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$params[0] += 2;
	print OINP "bond_coeff\t$params[0]\t$params[1]\t$params[2]\t$params[3]\n";
}
#Angles
while ($line = readline(SINP)) {
	print OINP "$line";
	if ($line =~ /.*angle_coeff 2.*/) {
		last;
	}
}
seek ALMP, 0, SEEK_SET;
while ($line = readline(ALMP)) {
	if ($line =~ /Angle Coeff.*/) {
		$line = readline(ALMP);
		last;
	}
}
while ($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$params[0] += 2;
	print OINP "angle_coeff\t$params[0]\tcharmm\t$params[1]\t$params[2]\t$params[3]\t$params[4]\n";
}
#Improper
while ($line = readline(SINP)) {
	if ($line =~ /improper_style.*/) {
		print OINP "improper_style hybrid distance harmonic\n";
		$line = readline(SINP);
		$line = readline(SINP);
		$line =~ s/1/1 distance/;
		print OINP "$line";
		last;
	} else {
		print OINP "$line";
	}
}

seek ALMP, 0, SEEK_SET;
while ($line = readline(ALMP)) {
	if ($line =~ /Improper Coeff.*/) {
		$line = readline(ALMP);
		last;
	}
}
while ($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$params[0] += 1;
	print OINP "improper_coeff\t$params[0]\tharmonic\t$params[1]\t$params[2]\t$params[3]\n";
}


#Dihedrals

print OINP "### Dihedral types ######\n";
seek ALMP, 0, SEEK_SET;
while ($line = readline(ALMP)) {
	if ($line =~ /Dihedral Coeff.*/) {
		$line = readline(ALMP);
		last;
	}
}
print OINP "dihedral_style harmonic\n";
while ($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
#	$params[0] += 1;
	print OINP "dihedral_coeff\t$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\t$params[5]\t$params[6]\n";
}

#move to pair

while ($line = readline(SINP)) {
	if ($line =~ /.*pair_style.*/) {
		$line =~ s/coul\/long 9.//;
		$line =~ s/lj\/cut/lj\/charmm\/coul\/long/;
		print OINP "$line";
		last;
	}
	print OINP "$line";
}


while ($line = readline(SINP)) {
	print OINP "$line";
	if ($line =~ /.*pair_modify.*/) {
		last;
	}
}

seek ALMP, 0, SEEK_SET;
while ($line = readline(ALMP)) {
	if ($line =~ /Pair Coeff.*/) {
		$line = readline(ALMP);
		last;
	}
}


while ($line = readline(ALMP)) {
	if (length($line) < 3 ) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$params[0] += 5;
	print OINP "pair_coeff\t$params[0]\t$params[0]\tlj/charmm/coul/long\t\t$params[1]\t$params[2]\t$params[3]\n";
}

while ($line = readline(SINP)) {
	print OINP "$line";
}
