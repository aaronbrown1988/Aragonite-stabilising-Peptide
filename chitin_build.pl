#!/usr/bin/perl

use Chemistry::Mol;
use Chemistry::File::PDB;
use Chemistry::Bond::Find  ':all';

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

for ($i =0; $i < 2; $i++) {
	for ($j = 0; $j < 2; $j++) {
		for ($k = 0; $k < 2; $k++) {
			foreach $line (@atoms) {
				@params = split(/\s+/, $line);
				$params[0] =~ tr/a-z/A-Z/;
				$params[1] *=$a;
				$params[2] *=$b;
				$params[3] *=$c;
				$x = $params[1];
				$y = $params[2];
				$z = $params[3];
				$params[1] +=$i*$a;
				$params[2] +=$j*$b;
				$params[3] += $k*$c;
				$mol->new_atom(symbol => $params[0], coords => [$params[1], $params[2], $params[3]]);
				

				# Screw axis parallel to b
				$y += 0.5 * $b;
				$z = -1*$z;

				$x += $i*$a;
				$y += $j * $b;
				$z += $k * $c;
				$mol->new_atom(symbol => $params[0], coords => [$x, $y, $z]);

					
			}
		}
	}
}

$mol->printf("%f\n");

find_bonds($mol);
$mol->write("out.pdb");

$mol->printf("Bonds: %b\n");
foreach $bond ($mol->bonds) {
	print $bond->print;
}

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
		
	close(GMX);
}
