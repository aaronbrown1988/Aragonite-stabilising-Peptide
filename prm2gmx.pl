#!/usr/bin/perl
#
#
#  Convert Charmm .prm ff files to a gmx ff
#
#


$cur_type = 0;
my %mass;
my %charge;
my %eps14;
my %sig14;

# conversion factor
$kj = 4.184;

open(PRM, $ARGV[0]) || die "couldn't open $ARGV[0]\n";

open(FFBOND, ">ffbonded.itp") || die "couldn't open ffbonded.itp for writing\n";
open(FFNBOND, ">ffnonbonded.itp") || die "couldn't open ffnonbonded.itp for writing\n";
open(ATP, ">atomtypes.atp") || die "couldn't open atomtypes for wiritng\n";



while($line = readline(PRM)) {
	if ($line =~ /^ATOMS.*/) {
		$cur_type = 'at';
		next;
	}elsif ($line =~ /^BONDS.*/) {
		$cur_type = 'b';
		print FFBOND "\n\n[ bondtypes ]\n";
		next;
	} elsif ($line =~ /^ANGLES.*/) {
		$cur_type = 'an';
		print FFBOND "\n\n[ angletypes ]\n";
		next;
	} elsif ($line =~ /^DIHEDRALS.*/) {
		$cur_type = 'dih';
		print FFBOND "\n\n[ dihedraltypes ]\n";
		next;
	} elsif($line =~ /^IMPROPER.*/) {
		$cur_type = 'imp';
		print FFBOND "\n\n[ dihedraltypes ]\n";
		next;
	}elsif ($line =~ /^NONBONDED.*/) {
		$cur_type = 'nb';
		print FFNBOND "[ atomtypes ]\n";
		next;
	}elsif ($line =~ /^END.*/) {
		last;
	} elsif ($line =~ /^[! \s].*/) {
		next;
	}

	if  ($cur_type eq 'at' ) { 
		atoms(); 
	} elsif ($cur_type eq 'b') { 
		bonds(); 
	} elsif ($cur_type eq 'an' ) {
		angles();
	} elsif ($cur_type eq 'dih') {
		dih();
	} elsif ($cur_type eq 'imp' ) {
		imp();
	} elsif ($cur_type eq 'nb') {
		nb();
	}
}

close(ATP);
close(FFBOND);


nb14();


close(FFNBOND);




sub atoms
{
	print "Doing atoms: $line \n";
	@params = split(/\s+/, $line);
	print ATP "$params[2]\t$params[3]\n";
	$mass{$params[2]} = $params[3];
	$charge{$params[2]} = 0.0;
	
}

sub bonds
{
	print "Doing Bonds: $line \n";
	@params = split(/\s+/, $line);
	$params[2] *= ($kj*2/0.01);
#	$params[3] *= 100;
	$params[3] /= 10;
	print FFBOND "$params[0]\t$params[1]\t1\t$params[3]\t$params[2]\n"
}

sub angles
{
	print "Doing Angles: $line \n";
	@params = split(/\s+/, $line);
	if ($params[5] eq '!') {
		$params[5] = 0.0;
		$params[6] = 0.0;
	}
	$params[3] *= $kj*2;
	$params[5] *= ($kj/0.01)*2;
	$params[6] /= 10;
	print FFBOND "$params[0]\t$params[1]\t$params[2]\t5\t$params[4]\t$params[3]\t$params[6]\t$params[5]\n"
} 
sub dih
{
	print "Doing Dihedrals: $line \n";
	@params = split(/\s+/, $line);
	$params[4] *= $kj;
	print FFBOND "$params[0]\t$params[1]\t$params[2]\t$params[3]\t9\t$params[6]\t$params[4]\t$params[5]\n"
}
sub imp
{
	print "Doing Impropers: $line \n";
	@params = split(/\s+/, $line);
	$params[4] *= $kj*2;
	print FFBOND "$params[0]\t$params[1]\t$params[2]\t$params[3]\t4\t$params[6]\t$params[4]\t$params[5]\n"
}

sub nb
{
	# I have knowingly ignored 1-4 interactions - Not any more AHB 2/11/12
	print "Doing nonbonded: $line \n";
	@params = split(/\s+/, $line);
	if ($params[2] > 0 ) {
		print "WHOA I don;t know tanford-kirkwood, skipping\n";
		return;
	}
	$params[2] *= -1;
	$params[2] *= $kj ; # Convert to Kjmol-1 from Kcalmol-1
	$params[3] /= 10; # convert A to nm
	$params[3] = $params[3]/(2**(1/6));
	$params[3] *= 2;
	
	
	#1-4's
	$params[5] *= -1;
	$params[5] *= $kj;
	$params[6] /= 10;
	$params[6] = $params[5]/ (2**(1/6));
	#$params[6] *= 2;
	
	if ($params[5] != /.*[A-Za-z].*/) {
		push(@lj14, $params[0]);
		$eps14{$params[0]} = $params[5];
		$sig14{$params[0]} = $params[6];
	}
	
	
	# Some magic numbers for the atomic number required by GMX.
	# We infer this from the first letter of the atom type which generally specifies the element
	if ($params[0] =~ /^C.*/) {
		$atnum = 6;
	}
	if ($params[0] =~ /^N.*/) {
		$atnum = 7;
	}
	if ($params[0] =~ /^O.*/) {
		$atnum = 8;
	}
	if ($params[0] =~ /^H.*/) {
		$atnum = 1;
	}
	if ($params[0] =~ /^P.*/) {
		$atnum = 15;
	}
	if ($params[0] =~ /^S.*/) {
		$atnum = 16;
	}
	$throw1=$mass{$params[0]};
	$throw2=$charge{$params[0]};
	print FFNBOND "$params[0]\t$atnum\t$throw1\t$throw2\tA\t$params[3]\t$params[2]\n";
}


sub nb14
{
	print FFNBOND "\n\n[ pairtypes ]\n";
	for($i = 0; $i< @lj14; $i++) {
		for ($j = $i; $j < @lj14; $j++) {
			$eps = sqrt ( $eps14{$lj14[$i]} * $eps14{$lj14[$j]});
			$sig = $sig14{$lj14[$i]} + $sig14{$lj14[$j]};
			print FFNBOND " $lj14[$i]\t$lj14[$j]\t1\t$sig\t$eps\n";
		}
	}
}
