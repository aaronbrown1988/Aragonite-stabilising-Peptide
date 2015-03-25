#!/usr/bin/perl
#
# Generates a module section for a DL_POLY field file from the
# output of the GMXDUMP. GMXDUMP output should contain just the one molecule surrounded
# by vacuuum. 
#
# USAGE gmx2dl.pl gmxdump.log 
# OUTPUT FIELD.frag
# 
#
# Caveats: Doesn't build LJ interactions

my $natoms = 0;
my $QQFUDGE=0.8333;
my $LJFUDGE=0.5;

open(IN, "$ARGV[0]") || die "Couldn't open $ARGV[0]: $!\n";

while ($line = readline(IN)) {
	$line =~ s/^\s+//;
	chomp($line);
	push (@buf, $line);
	if ($line =~ /#atoms_mol.*=/) {
		$line =~ s/^\s+//;
		chomp($line);
		@params = split(/\s+/, $line);
		$natoms = $params[2];
	}
}

#
# Build LUT for func and atn
#
$find = 0;
for ($i = 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /.*ffparams.*/) {
		$find = $i;
		last;
	}
}

$natn = $buf[$find+1];
$ntypes = $buf[$find+2];
$natn =~ s/.*=//;
$ntypes =~ s/.*=//;

for ($i=$find+3; $i < ($find+2+$ntypes); $i++ ) {
	$line = $buf[$i];
	$line =~ s/.*functype.*\]=//;
	push(@func,$line);
}


#
# Output header for the field file
#
open (OUT, ">FIELD.frag") || die "Couldn't open FIELD.frag:$!\n";
print OUT "Fragment\n";
print OUT "NUMMOLS     1\n";
print OUT "ATOMS     $natoms\n";

#
# Find atoms and output atoms
#
$find=0;
for ($i=0; $i < scalar(@buf); $i++) {
	$line = $buf[$i];
	if ($find == 2 ) {
		$find = $i;
		last;
	}
	if ($line =~ /.*moltype \(0\):.*/) { $find ++; }
	if ($line =~ /.*atom \($natoms\)/) {$find ++;}
}

#Read in atom properties, like mass and charge.
for ($i = $find; $i < ($find+$natoms); $i++) {
	$line = $buf[$i];
	$line =~ s/.*\{//;
	$line =~ s/\}.*//;
	push(@at, $line);
}
# Read in atom names (Currently pdb names, might need to make this types
for ($i = ($find+$natoms+1); $i < ($find +2*$natoms+1); $i++) {
	$line = $buf[$i];
	$line =~ s/.*name=\"//;
	$line =~ s/\"\}.*//;
	chomp($line);
	push(@atname, $line);
}

#Read in atom types
$find = $find +2*$natoms+2;
for($i = $find; $i < ($find +$natoms);$i++) {
	$line = $buf[$i];
	$line =~ s/.*name=\"//;
	$line =~ s/\".*//;
	chomp($line);
	push(@attype,$line);
}

#
# Output Atoms in the molecule
for ($i = 0; $i < $natoms; $i++) {
	$mass = $at[$i];
	$q = $mass;
	$mass =~ s/.*, m=//;
	$mass =~ s/, .*//;
	$q =~ s/.*, q=//;
	$q =~ s/, .*//;
	chomp($q);
	chomp($mass);

	print OUT "    $attype[$i]    $mass   $q\n";
	#print OUT "    $atname[$i]    $mass    $q\n";
}

undef @at;
undef @atname;

#
# Bonds
#

#Find Bonds and get total number 
$nbonds = 0;
for ($i= 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /.*Bond:.*/) {
		$find = $i+3;
		last;
	}
}
for($i=$find; $i<scalar(@buf); $i++) {
	if ($buf[$i] !~ /.*BOND.*/) { last;}
	$nbonds++;
}
#
# Process bonds and write them out.
#
# I'm assuming harm
print OUT "BONDS      $nbonds\n";
for ($i=$find; $i < scalar(@buf); $i++ ){
	$line = $buf[$i];
	$line =~ s/^\s+//;
	chomp($line);
	if ($line !~ /.*BOND.*/) {
		last;
	}
	@params = split(/\s+/, $line);
	$type = $params[1];
	$type =~ s/.*=//;
	chomp($type);
	$type = $func[$type];
	$b0 = $type;
	$b0 =~ s/.*b0A=//;
	$b0 =~ s/,.*//;
	$b0 *= 10;
	$cb = $type;
	$cb =~ s/.*cbA=//;
	$cb =~ s/,.*//;
	$cb *= 1e-4;
	$params[3]++;
	$params[4]++;
	print OUT "harm    $params[3]    $params[4]    $cb    $b0\n";
}	

#
# Angles
#
#Find Angles and get total number 
$nangles = 0;
for ($i= 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /.*Angle:.*/) {
		$find = $i+3;
		last;
	}
}
for($i=$find; $i<scalar(@buf); $i++) {
	if ($buf[$i] !~ /.*ANGLES.*/) { last;}
	$nangles++;
}
#
# Process Angles and write them out.
#
# I'm assuming cosine
print OUT "ANGLES      $nangles\n";
for ($i=$find; $i < scalar(@buf); $i++ ){
	$line = $buf[$i];
	$line =~ s/^\s+//;
	chomp($line);
	if ($line !~ /.*ANGLES.*/) {
		last;
	}
	@params = split(/\s+/, $line);
	$type = $params[1];
	$type =~ s/.*=//;
	chomp($type);
	$type = $func[$type];
	$th = $type;
	$th =~ s/.*thA=//;
	$th =~ s/,.*//;
	$ct = $type;
	$ct =~ s/.*ctA=//;
	$ct =~ s/,.*//;
	$ct *= 0.01;
	$params[3]++;
	$params[4]++;
	$params[5]++;
	print OUT "harm    $params[3]    $params[4]    $params[5]    $ct    $th\n";



}

#
#
# Proper Dihedrals 
#

#Find Dih and get total number 
$npdih = 0;
for ($i= 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /.*Proper Dih.:.*/) {
		$find = $i+3;
		last;
	}
}
for($i=$find; $i<scalar(@buf); $i++) {
	if ($buf[$i] !~ /.*PDIHS.*/) { last;}
	$npdih++;
}
$nidih = 0;
for ($i= 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /.*Improper Dih.:.*/) {
		$ifind = $i+3;
		last;
	}
}
for($i=$ifind; $i<scalar(@buf); $i++) {
	if ($buf[$i] !~ /.*PIDIHS.*/) { last;}
	$nidih++;
}
#
# Process Dih and write them out.
#
# I'm assuming cos for propers, and cos for impropers
$total = $npdih + $nidih;
print OUT "DIHEDRALS      $total\n";
for ($i=$find; $i < scalar(@buf); $i++ ){
	$line = $buf[$i];
	$line =~ s/^\s+//;
	chomp($line);
	if ($line !~ /.*PDIHS.*/) {
		last;
	}
	@params = split(/\s+/, $line);
	$type = $params[1];
	$type =~ s/.*=//;
	chomp($type);
	$type = $func[$type];
	$phi = $type;
	$phi =~ s/.*phiA=//;
	$phi =~ s/,.*//;
	$cp = $type;
	$cp =~ s/.*cpA=//;
	$cp =~ s/,.*//;
	$cp *= 0.01;
	$m= $type;
	$m =~ s/.*mult=//;
	$m =~ s/,.*//;
	$params[3]++;
	$params[4]++;
	$params[5]++;
	$params[6]++;
#print OUT "cos    $params[3]    $params[4]    $params[5]    $params[6]    $phi    $cp    $m\n";
	print OUT "cos     $params[3]    $params[4]    $params[5]    $params[6]    $cp    $phi    $m    $QQFUDGE    $LJFUDGE\n";
}

#Impropers
for ($i=$ifind; $i < scalar(@buf); $i++ ){
	$line = $buf[$i];
	$line =~ s/^\s+//;
	chomp($line);
	if ($line !~ /.*PIDIHS.*/) {
		last;
	}
	@params = split(/\s+/, $line);
	$type = $params[1];
	$type =~ s/.*=//;
	chomp($type);
	$type = $func[$type];
	$phi = $type;
	$phi =~ s/.*phiA=//;
	$phi =~ s/,.*//;
	$cp = $type;
	$cp =~ s/.*cpA=//;
	$cp =~ s/,.*//;
	$cp *= 0.01;
	$m= $type;
	$m =~ s/.*mult=//;
	$m =~ s/,.*//;
	$params[3]++;
	$params[4]++;
	$params[5]++;
	$params[6]++;
	# This might need some kind of space filling between the params and the fudge factor
	print OUT "cos     $params[3]    $params[4]    $params[5]    $params[6]    $cp    $phi    $m    $QQFUDGE    $LJFUDGE\n";

}	
print OUT "FINISH\n";
close(OUT);


open(CONF, ">CONFIG.frag") || die " Couldn't open config for writing:$!\n";

#
# Find Box dimensions
#
my $x =0;
my $y = 0;
my $z = 0;
for($i = 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /^box \(3x3\):.*/) {
		@params = split(/\s+/, $buf[$i+1]);
		$x = $params[2];
		@params = split(/\s+/, $buf[$i+2]);
		$y = $params[3];
		@params = split(/\s+/, $buf[$i+3]);
		$z = $params[4];
		last;
	}
}
$x *= 10;
$y *= 10;
$z *= 10;
print "$x $y $z\n";
print CONF "TEST\n";
print CONF "       0        2      $natoms\n";
printf CONF "%-020f %-20f %-20f\n",$x, 0.0, 0.0;
printf CONF "%-20f %-20f %-20f\n",0.0, $y, 0.0;
printf CONF "%-20f %-20f %-20f\n",0.0, 0.0, $z;

for (; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /^x \($natoms.3\):.*/) {
		$found = $i+1;
		last;
	}
}


for($i = 0; $i < $natoms; $i++) {
	$line = $buf[$found+$i];
	chomp($line);
	$line =~ s/.*\{\s+//;
	$line =~ s/\}.*//;
	@params = split(/,/, $line);
	print "@params\n";
	$j = $i+1;
	$params[0] *= 10;
	$params[1] *= 10;
	$params[2] *= 10;
	print CONF "$attype[$i]           $j\n";
	printf CONF "     %-020f  %-020f %-020f\n", $params[0],$params[1], $params[2];
}


		
