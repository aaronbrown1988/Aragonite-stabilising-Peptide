#!/usr/bin/perl

use Chemistry::Mol;
use Chemistry::File::PDB;
use Chemistry::Bond::Find  ':all';
use Chemistry::Ring::Find  ':all';
use Chemistry::File::SMILES;
use Chemistry::3DBuilder qw(build_3d);
my $proto = Chemistry::Mol->new(id=>'Proto');

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



open(CHT, ">cht.pdb");
$at = 0;
$ch = 0;
$res=0;
for ($i =0; $i < 1; $i++) {
	for ($j = 0; $j < 1; $j++) {
		for ($k = 0; $k < 1; $k++) {
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
				$params[1] +=$i*$a;
				$params[2] +=$j*$b;
				$params[3] += $k*$c;
				if ($params[0] eq 'C1') {
					$coff++;
					$res++;
				}
				$at++;
				
				$mol->new_atom(symbol => $params[0], type => $params[0], name=>$params[0], coords => [$params[1], $params[2], $params[3]]);
				printf("%-6s%5d%5s%1s%3s%1s%3d%1s%8.3f%8.3f%8.3f\n","ATOM", $at,$params[0],' ',"CHT",$ch+$coff,'a',$res,'b',$params[1], $params[2], $params[3]);
			}
		}
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



exit;



#### No Longer needed Hopfully #### 


@atoms = $mol->atoms();
$mol->new_bond(atoms => [$atoms[13], $atoms[6]], order => 2);


find_bonds($mol,  tolerance => 1.2);


#assign_bond_orders($mol, method => 'baber');
@tofix = $mol->atoms_by_name("O7");



# Fix bond orders
@bonds = $mol->bonds();
for ($i =0; $i < @bonds; $i++) {
	$bfix = $mol->by_id($bonds[$i]);
	$bfix->order(1);
}

for ($i =0; $i < @tofix; $i++) {
	$afix = $mol->by_id($tofix[$i]);
	@bn = $afix->bonds_neighbors();
	$bfix = $bn[0]->{bond};
	print "fixing $afix $bn $bfix\n";
	$bfix->order(2.0);
}



# Add implicit hydrogens
#$mol->add_implicit_hydrogens();
#$mol->sprout_hydrogens();

$c1 = $mol->by_id($mol->atoms_by_name('C1'));
$c1->sprout_hydrogens();
@neigh = $c1->neighbors();
foreach $_ (@neigh) {
 if($_->symbol =~ /H.*/) {
	print "$_\n";
	my $ic = Chemistry::InternalCoords->new(
        $_, $c1, 1.152, $neigh[1], 110.1
    );
	$_->coords($ic->cartesians);
}}

read_prototype();
apply_prototype();



$mol->printf("%s - %n (%f). %a atoms, %b bonds; ","mass=%m; charge =%q; type=%t; id=%i");






sub apply_prototype
{
	my @params;
	my $redo=0;
	@atoms = $mol->atoms();
	for($i = 0; $i < @atoms; $i++) {
		$at = $mol->by_id($atoms[$i]);
		$at->add_implicit_hydrogens();
		$at->sprout_hydrogens();
		if ($at->total_hydrogens == 0) {
			next;
		}

		print "Fixing $at - ", $at->name,"..";
		@neighbors = $at->neighbors();
		$hval = ($at->name =~ /(.T|C6)/)? 1: "";
		$hpref = $at->name;
		$hpref = "H$hpref";
		$hpref =~ s/C//;
		print "Found @neighbors...";
		foreach $tmp (@neighbors) {
			if ($tmp->symbol !~ /.*H.*/) {
				next;
			}

			$hn = "$hpref$hval";
			print ".....Placing $hn - ",$tmp,"...";
			for ($k = 0; $k < @ic; $k++) {
				if ($ic[$k] !~ /.*$hn.*/) {
					next;
				}
				@params = split(/\s+/,$ic[$k]);
			#	print "$ic[$k] applies to $hn\n";
				$tmp->name($hn);
				# Probably a better way than this:
				@coords= [];
				$params[3] =~ s/^\*//;
				@matched = grep {$_->name eq $params[2]} @neighbors;
#				print "$params[2] ",$at->name,"=",$params[3],"\n";
				
				if ($params[4] =~ /.*$hn.*/ && $at->name eq $params[3] ) {
#					print "Matched $params[3] and $params[4]\n";
					@dih = [];
					if ($matched[0] != '') {
						print $matched[0]->name," is needed in ic def...\n";
						@dih = grep {$_->name eq $params[1]} $matched[0]->neighbors;
						print "$tmp,$at,$params[9],$matched[0],$params[8],$dih[0],$params[7]\n";
						if (@dih >  0 ) {
							print "I have an idea on dih\n";
							$ic = Chemistry::InternalCoords->new($tmp,$at, $params[9], $matched[0], $params[8]);#, $dih[0], -$params[7]);
						} else {
							$ic = Chemistry::InternalCoords->new($tmp,$at, $params[9], $matched[0], $params[8]);
						}
						$tmp->coords($ic->cartesians);
					} else {
						print "Angles didn't match?!?!?!\n";
						$redo = 1;
					}

				}


				


			}
			$hval++;
		}

				
	}
	if ($redo == 1) {
		apply_prototype();
	}
}







sub read_prototype
{
	my $line;
	my $params;
	open(STR, $ARGV[1]) || die "Couldn't open charmm residue file: $ARGV[1]\n";
	while ($line = readline(STR)){
		if ($line =~ /.*BGLCNA.*/) {
			last;
		}
	}
	$line = readline(STR);
	$line = readline(STR);
	while ($line = readline(STR)) {
		if (length($line) < 3) {
			last;
		}
		@params = split(/\s+/,$line);
	#	$proto->add_atom( name => $params[1], type => $params[2], formal_charge=>$params[3]);
	}

	while ($line = readline(STR)) {
		if ($line =~ /IMPR.*/) {
			last;
		}
		@params = split(/\s+/,$line);
		for ($i = 0; $i < @params; $i += 2) {
			$proto->new_bond(atoms => [$proto->atoms_by_name($params[$i]),$proto->atoms_by_name($params[$i+1])] );	
		}
	}
	
	$line = readline(STR);
	$line = readline(STR);
#	print $line;
	while ($line = readline(STR)) {
		if ($line !~ /IC.*/) {
		#	print "Finished as just read $line from IC table\n";
			last;
		}
		chomp($line);
		push(@ic,$line);
	#	@params->
	}
	close(STR);


}

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


