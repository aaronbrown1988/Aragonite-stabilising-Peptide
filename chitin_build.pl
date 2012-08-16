#!/usr/bin/perl

use Chemistry::Mol;
use Chemistry::File::PDB;


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

#screw || c
$atnum = @atoms;
for($i = 0; $i < $atnum; $i++) {
	$line = $atoms[$i];
	@params = split(/\s+/, $line);
	$x = $params[1];
	$y = $params[2];
	$z = $params[3];
	
	# Screw axis parallel to c
	$z += 0.5;# * $c;
	$y = -1*$y;
	$x = -1*$x;

	$line = "$params[0]\t$x\t$y\t$z\n";
	push(@atoms, $line);
}


# Screw || b
$atnum = @atoms;
for($i = 0; $i < $atnum; $i++) {
	$line = $atoms[$i];
	@params = split(/\s+/, $line);
	$x = $params[1];
	$y = $params[2];
	$z = $params[3];

	# Screw axis parallel to b
	$y += 0.5;# * $b;
	$z = -1*$z+1;
	$x = -1*$x;
#
	$line = "$params[0]\t$x\t$y\t$z\n";
#	push(@atoms, $line);
}


#screw || a
$atnum = @atoms;
for($i = 0; $i < $atnum; $i++) {
	$line = $atoms[$i];
	@params = split(/\s+/, $line);
	$x = $params[1];
	$y = $params[2];
	$z = $params[3];

	# Screw axis parallel to b
	$x += 0.5;
	$z = -1*$z+1;
	$y = -1*$y+0.5;
	$line = "$params[0]\t$x\t$y\t$z\n";
#	push(@atoms, $line);
}



$at = 0;
$ch = 0;
$res=0;
$line = @atoms[22];
@params = split(/\s+/, $line);
$params[0] =~ tr/a-z/A-Z/;
$sym = $params[0];
$sym =~ /(.).*/;
$sym = $1;
$params[1] *=$a;
$params[2] *=$b;
$params[3] *=$c;
$params[3] += -1*$c;
$mol->new_atom(symbol => 'O4', type => 'O4', name=>'O4', coords => [$params[1], $params[2], $params[3]]);
for ($k = 0; $k < 5; $k++) {
	$coff = 0;
	foreach $line (@atoms) {
		@params = split(/\s+/, $line);
		$params[0] =~ tr/a-z/A-Z/;
		$sym = $params[0];
		$sym =~ /(.).*/;
		$sym = $1;
		$params[1] *=$a;
		$params[2] *=$b;
		$params[3] *=$c;
		$params[3] += $k*$c;
		if ($params[0] eq 'C1') {
			$coff++;
			$res++;
		}
		$at++;
		
		$mol->new_atom(symbol => $params[0], type => $params[0], name=>$params[0], coords => [$params[1], $params[2], $params[3]]);
	}
}





@atoms = $mol->atoms;

for($i = 0; $i < @atoms; $i++ ) {
	$at = $mol->by_id($atoms[$i]);
	$tmp = $at->name;
	$at->symbol("$tmp");
#	$at->type($at->name);
	print $at{type};
}
	


$mol->write("out.pdb");

