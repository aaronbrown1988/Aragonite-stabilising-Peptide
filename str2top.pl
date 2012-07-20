#!/usr/bin/perl
#
# converts the specified charmm residue to an gromacs topology file
# and pdb for good measure.
#
use Chemistry::Mol;
use Chemistry::File::PDB;
use Chemistry::File::SMILES;
use Chemistry::3DBuilder qw(build_3d);
use Chemistry::Bond::Find ':all';


my %mass;

open(STR, $ARGV[0]) || die "couldn't open $ARGV[0] for reading\n";
print "looking for $ARGV[1]\n";

# skip down to residue of interest
while ($line = readline(STR)) {
	if ($line =~ /.*$ARGV[1].*/) {

		print "Found $ARGV[1]\n";
		last;
	
	}
}
$line = readline(STR);
$line = readline(STR);
#print $line;
$mol = Chemistry::Mol->new(id=>$ARGV[1], name => $ARGV[1]);
while ($line = readline(STR)) {
	if ($line=~/GROU.*/) {
		next;
	} elsif (length($line) < 4) {
		last;
	}

	@params = split(/\s+/, $line);
	$sym = $params[1];
	$sym =~ m/^./;
	$mol->new_atom(name=> $params[1], symbol => $sym, type => $params[2], formal_charge => $params[3]);
#	print "adding $params[1] with charge $params[3]\n";
}

while ($line = readline(STR)) {
	if ($line !~ /^BOND.*/) {
		print $line;
		last;
	}
	$line =~ s/BOND\s+//;
	@params = split(/\s+/,$line);
	for ($i=0; $i < @params; $i+=2) {
		$mol->new_bond(atoms => [$mol->atoms_by_name($params[$i]),$mol->atoms_by_name($params[$i+1])] );
		print "added bond\n";
	}
}
#We build our own dih and angles (for better or for worse) so we are done with the topology
#close (STR);

#See if parameters are near by, if so populate mass
if ( -f "./atomtypes.atp") {
	print "Found atomtypes knocking around, can fill in the masses\n";
	open (FF, "./atomtypes.atp");
	while ($line2 = readline(FF)) {
		@params = split(/\s+/, $line2);
		$mass{$params[0]} = $params[1];
	}
	close(FF);
}







find_angles();
find_dih();

#read_ic();

write_top();







sub find_dih
{
	my $i; #
	my $j; ###
	my $k; #### Loop variables 
	my $l; #
	my @bonds = $mol->bonds();

	for ($i = 0; $i < @bonds; $i++ ) {
		for ($j = 0; $j < @bonds; $j++) {
			if ($i == $j) { next;}
			for ($k = 0; $k < @bonds; $k++) {
					if( $k == $i || $k == $j) { next;}
					@aa = $bonds[$i]->atoms();
					@ab = $bonds[$j]->atoms();
					@ac = $bonds[$k]->atoms();
					sort(@aa);
					sort(@ab);
					sort(@ac);
					#
					# Decide on bond order
					#
					if ($aa[1] eq $ab[0] && $ab[1] eq $ac[0] ) {
#						print "a-b-c\n";
						push(@dihedrals, "$aa[0]-$ab[0]-$ab[1]-$ac[1]");
					} elsif ($aa[1] eq $ac[0] && $ac[1] eq $ab[0]) {
#						print "a-c-b\n";
						push(@dihedrals, "$aa[0]-$ac[0]-$ac[1]-$ab[1]");
					} elsif ($ab[1] eq $aa[0] && $aa[1] eq $ac[0]) {
#						print "b-a-c\n";
						push(@dihedrals, "$ab[0]-$aa[0]-$aa[1]-$ac[1]");
					} else {
					#	print "I don't think @aa @ab @ac make a dihedral\n";
					}

			}
		}
	}
}

sub find_angles
{
	my $i; #
	my $j; ###
	my @bonds = $mol->bonds();

	for ($i = 0; $i < @bonds; $i++ ) {
		for ($j = 0; $j < @bonds; $j++) {
			if ($i == $j) { next;}
			@aa = $bonds[$i]->atoms();
			@ab = $bonds[$j]->atoms();
			sort(@aa);
			sort(@ab);
			#
			# Decide on bond order
			#
			if ($aa[1] eq $ab[0] ) {
			#	print "a-b\n";
				push(@angles, "$aa[0]-$ab[0]-$ab[1]");
			} elsif ($aa[1] eq $ab[1] ) {
				push(@angles, "$aa[0]-$ab[1]-$ab[0]");
			}elsif ( $aa[0] eq $ab[0] ) {
				push (@angles, "$aa[1]-$aa[0]-$ab[1]");
			}elsif ( $aa[0] eq $ab[1] ) {
				push (@angles, "$aa[1]-$aa[0]-$ab[0]");

			} else {
			#	print "I don't think @aa @ab make an  angle\n";
			}

			
		}
	}
}

sub write_top
{
	my $i=1;
	open (TOP, ">$ARGV[1].top") || die "couldn't open out.top for writing \n";

	#preammble

	print TOP "#include \"./forcefield.itp\"\n";

	print TOP "[ moleculetype ]\n";
	print TOP "; Name            nrexcl\n";
	print TOP "Other             3\n\n\n\n";




	print TOP "[ atoms ]\n";
	foreach $atom ($mol->atoms()) {
		$sym = $atom->name();
		$type = $atom->type();
		$charge = $atom->formal_charge();
		print TOP ("$i\t$type\t1\tCHT\t$sym\t$i\t$charge\t$mass{$type}\n");
		$i++;
	}
	

	print TOP "\n\n";
	print TOP "[ bonds ]\n";
	foreach $bond ($mol->bonds) {
		@atoms = $bond->atoms();
		$atoms[0] =~ s/a//;
		$atoms[1] =~ s/a//;
		
		print TOP  "@atoms\t1\n";
	}

	print TOP "\n\n";
	print TOP "[ angles ]\n";
	foreach $ang (@angles) {
		$ang =~ s/a//g;
		$ang =~ s/-/\t/g;
		print TOP "$ang\t 5\n";
	}

	print TOP "\n\n";
	print TOP  "[ dihedrals ]\n";
	for($i =0; $i < @dihedrals; $i++ ) {
		$dih = $dihedrals[$i];
		$dih =~ s/a//g;
		$dih =~ s/-/\t/g;
		print TOP "$dih\t9\n";
	}

	print TOP "\n\n";
	print TOP "\n\n";
	print TOP  "[ dihedrals ]\n";
	for($i =0; $i < @imp; $i++ ) {
		$dih = $imp[$i];
		$dih =~ s/a//g;
		$dih =~ s/-/\t/g;
		print TOP "$dih\t4\n";
	}
	

	print TOP "\n\n";
	print TOP "[ System ]\n";
	print TOP "; Name\n";
	print TOP $mol->name;
	print TOP "\n\n";
	print TOP "[ molecules ]\n";
	print TOP "Other\t 1\n";

	close(TOP);
}


sub read_ic
{
	#
	# Reads the IC table from charmms rtf topology to attempt to combat not having enough dihedrals and angles defined
	#
	do {
		@params = split(/\s+/, $line);
		# COnvert to atom numbers
		$a[0] = $mol->atoms_by_name($params[1]);
		$a[1] = $mol->atoms_by_name($params[2]);
		$a[3] = $mol->atoms_by_name($params[4]);

		if ($line =~ /IMPR.*/) {
			$a[2] = $mol->atoms_by_name($params[3]);
			# line contains an improper
			$line =~ s/IMPR //;
			$line =~ s/\n//;
			$line =~ s/\s+/-/g;
			push(@imp, "$a[0]-$a[1]-$a[2]-$a[3]");
		} elsif ($line =~ /IC.*/) {
			next;
			# Line contains IC record
			

			if ($params[3] =~ /\*.*/) {
				#is improper
				$params[3] =~ s/\*//;
				$a[2] = $mol->atoms_by_name($params[3]);
				if ($params[7] < 0) {
					push(@imp, "$a[3]-$a[1]-$a[2]-$a[0]");
				} else {
					push(@imp, "$a[0]-$a[1]-$a[2]-$a[3]");

				}
			} else {
				$a[2] = $mol->atoms_by_name($params[3]);
				if ($params[7] < 0) {
					push(@dihedrals, "$a[3]-$a[1]-$a[2]-$a[0]");
				} else {
					push(@dihedrals, "$a[0]-$a[1]-$a[2]-$a[3]");
				}
			#Angles from the line
			push (@angles, "$a[0]-$a[1]-$a[2]");
			push (@angles, "$a[1]-$a[2]-$a[3]");
			}


		}
		$line = readline(STR);
	} while  (length($line) > 3);

}


