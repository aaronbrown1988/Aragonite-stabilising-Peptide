#!/usr/bin/perl
#
# covert an arbitrary xyz to a gro (aimed at Chitin)
#



################################ packages #####################
use Chemistry::Mol;
use Chemistry::File::PDB;
use Chemistry::Bond::Find ':all';


########### Globals ###################
my @angles;
my @dihedrals;
my @dihtypes; # LUT used to distinguish between improper and regular dihedrals

my %mass;
my %charge;
my %atlut= (HOx=>'H', HxO=> 'H', CxN => 'NC2', CME => 'CT3' , HxM => 'HA1', OxN => 'OC', Cx => 'CT3', Ox => 'OH1', Hx => 'H', HxN => 'H', Nx=> 'NC2');


########### The doing #############
$mol = Chemistry::Mol->read($ARGV[0]);

find_bonds($mol, tolerance=>1.4);

find_angles();
find_dih();
read_gmx();

write_top();



sub find_dih
{
	my $i; #
	my $j; ###
	my $k; #### Loop variables 
	my $l; #
	my @bonds = $mol->bonds();

	for ($i = 0; $i < @bonds; $i++ ) {
		for ($j = $i; $j < @bonds; $j++) {
			for ($k = $j; $k < @bonds; $k++) {
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
		for ($j = $i; $j < @bonds; $j++) {
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
			} elsif ($aa[1] eq $ab[0] ) {
				push(@angles, "$aa[0]-$ab[1]-$ab[0]");

			} else {

				#print "I don't think @aa @ab make an  angle\n";
			}

			
		}
	}
}

sub write_top
{
	my $i=1;
	open (TOP, ">out.top") || die "couldn't open out.top for writing \n";
	print TOP "[ atoms ]\n";
	foreach $atom ($mol->atoms()) {
		$sym = $atom->name();
		$sym =~ s/[0-9]+/x/g;
		print TOP ("$i\t$atlut{$sym}\t1\tCHT\t$sym\t$i\t$charge{$atlut{$sym}}\t$mass{$atlut{$sym}}\n");
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
		print TOP "$dih\t$dihtypes[$i]\n";
	}

	print TOP "\n\n";
	print TOP "[ System ]\n";
	print TOP "; Name\n";
	print TOP $mol->name;
	print TOP "\n\n";
	print TOP "[ molecules ]\n";
	print TOP "Protein\t 1\n";

	close(TOP);
}


sub read_gmx
{
	open(FF, "$ARGV[1]/ffnonbonded.itp") || die "couldn't open $ARGV[1]/ffnonbonded.itp : $!\n";
	readline(FF);
	readline(FF);
	while ($line = readline(FF)) {
		if (length($line) < 4 ) {
			last;
		}
		if ($line =~ /^[;!]/) {
#	continue;
		}
		@params = split(/\s+/, $line);
		$mass{$params[0]} = $params[2];
		$charge{$params[0]} = $params[3];
	}

	close(FF);
}
