#!/usr/bin/perl

use Chemistry::Mol;
use Chemistry::File::PDB;
use Chemistry::Bond::Find  ':all';
use Chemistry::Ring::Find  ':all';
use Chemistry::File::SMILES;
use Chemistry::3DBuilder qw(build_3d);


#
# Hopefully build a slab of chitin in a PDB
#

open(FRAC, $ARGV[0]) || die "Couldn't open fractional Co-ordinates file, $ARGV[0],: $!\n";

$a = readline(FRAC);
$b = readline(FRAC);
$c = readline(FRAC);


$mol = Chemistry::Mol->new(id => 'beta', name => 'Beta-Chitin');
while ($line = readline(FRAC)) {
	push(@atoms, $line);
}




for ($i =0; $i < 1; $i++) {
	for ($j = 0; $j < 1; $j++) {
		for ($k = 0; $k < 1; $k++) {
			foreach $line (@atoms) {
				@params = split(/\s+/, $line);
				$params[0] =~ tr/a-z/A-Z/;
				$sym = $params[0];
				$sym =~ s/[0-9].*//;
				$params[1] *=$a;
				$params[2] *=$b;
				$params[3] *=$c;
				$x = $params[1];
				$y = $params[2];
				$z = $params[3];
				$params[1] +=$i*$a;
				$params[2] +=$j*$b;
				$params[3] += $k*$c;
				$mol->new_atom(symbol => $sym, name=>$params[0], coords => [$params[1], $params[2], $params[3]]);
				

				# Screw axis parallel to b
				$y += 0.5 * $b;
				$z = -1*$z;

				$x += $i*$a;
				$y += $j * $b;
				$z += $k * $c;
			#	$mol->new_atom(symbol => $params[0], coords => [$x, $y, $z]);  # Screw axis reflection

					
			}
		}
	}
}
@atoms = $mol->atoms();
$mol->new_bond(atoms => [$atoms[13], $atoms[6]], order => 2);



find_bonds($mol,  tolerance => 1.2);

#assign_bond_orders($mol, method => 'baber');



$mol->add_implicit_hydrogens();
$mol->sprout_hydrogens();
find_bonds($mol,  tolerance => 1.2);

build_3d($mol);
#$mol->printf("%f\n");
#print "Mass: ",$mol->mass, "\n";
#print "Charge: ",$mol->charge, "\n";



$mol->printf("%s - %n (%f). %a atoms, %b bonds; ","mass=%m; charge =%q; type=%t; id=%i");

$mol->write("out.pdb");

for $atoms ($mol->atoms) {
	print $atoms->symbol();
#	print $atoms->valence();
	
	print $atoms->implicit_hydrogens(), "\n";
}





$mol->printf("Bonds: %b\n");
foreach $bond ($mol->bonds) {
	print $bond->print;
}


#@rings = find_rings($mol);
#foreach $ring (@rings) {
#	$ring->printf("%s - %n (%f). %a atoms, %b bonds; ","mass=%m; charge =%q; type=%t; id=%i");
#
#}


write_gmx();



sub write_gmx {
	# Start writing topology file
	open(GMX, ">out.top") || die "Couldn't open out.top for writing\n";
	$i = 0;
	print GMX "[ atoms ]\n";
	foreach $atom ($mol->atoms) {
		$sym = $atom->symbol();
		print GMX ("$i  $sym  1  $sym  1 0.0 0.0\n");
		$i++;
	}
	print GMX "\n[ bonds ]\n";
	foreach $bond ($mol->bonds) {
		@atoms = $bond->atoms();
		$atoms[0] =~ s/a//;
		$atoms[1] =~ s/a//;
		
		print GMX "@atoms 1\n";
	}

	print GMX "\n[ angles ]\n";
	@bonds = $mol->bonds;
	for ($i=0; $i < @bonds; $i++ ) {
		@aa = $bonds[$i]->atoms();
		for ($j = $i+1; $j < @bonds; $j++) {
			@ab = $bonds[$j]->atoms();
			$ab[0] =~ s/a//;
			$ab[1] =~ s/a//;
			$aa[0] =~ s/a//;
			$aa[1] =~ s/a//;
			if ($ab[0] eq $aa[0]) {
				print GMX "$aa[1] $aa[0] $ab[1] 5\n";
			} elsif ($ab[0] eq $aa[1] ) {
				print GMX "$aa[0] $aa[1] $ab[1] 5\n";
			} elsif ($ab[1] eq $aa[0] ) {
				print GMX "$aa[1] $aa[0] $ab[0] 5\n";
			} elsif ($ab[1] eq $aa[1]) {
				print GMX "$aa[0] $aa[1] $ab[0] 5\n";
			}
		}
	}

	print GMX "\n[ dihedrals ]\n";
	foreach $ba ($mol->bonds) {
		@aa = $ba->atoms();
		foreach $bb ($mol->bonds) {
			@ab = $bb->atoms();
			foreach $bc ($mol->bonds) {
				@ac = $bc->atoms();
				$ab[0] =~ s/a//;
				$ab[1] =~ s/a//;
				$aa[0] =~ s/a//;
				$ac[0] =~ s/a//;
				$ac[1] =~ s/a//;
				$aa[1] =~ s/a//;
				
				if ($aa[1] eq $ab[0] && $ab[1] eq $ac[0]) {
					print GMX "$aa[0] $ab[0] $ab[1] $ac[1] 9\n";
				}
				if ($aa[1] eq $ac[0] && $ac[1] eq $ab[0]) {
					print GMX "$aa[0] $aa[1] $ac[1] $ab[1] 9\n";
				}
			}
		}
	}


	
	close(GMX);
}


