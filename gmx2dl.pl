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
# Caveats:Just format conversion, Uses GMX units currently

my $natoms = 0;

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
print OUT "NUMMOLS\t 1\n";
print OUT "ATOMS\t $natoms\n";

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

	print OUT "\t$atname[$i]\t$mass\t$q\n";
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
		$nbonds = $buf[$i+1];
		$nbonds =~ s/.*nr..//;
		chomp($nbonds);
		$find = $i+3;
		last;
	}
}
#
# Process bonds and write them out.
#
# I'm assuming harm
print OUT "BONDS \t $nbonds\n";
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
	$cb = $type;
	$cb =~ s/.*cbA=//;
	$cb =~ s/,.*//;
	$params[3]++;
	$params[4]++;
	print OUT "harm\t$params[3]\t$params[4]\t$b0\t$cb\n";



}	


#
# Angles
#

#Find Angles and get total number 
$nangles = 0;
for ($i= 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /.*Angle:.*/) {
		$nangles = $buf[$i+1];
		$nangles =~ s/.*nr..//;
		chomp($nangles);
		$find = $i+3;
		last;
	}
}
#
# Process Angles and write them out.
#
# I'm assuming cosine
print OUT "ANGLES \t $nbonds\n";
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
	$params[3]++;
	$params[4]++;
	$params[5]++;
	print OUT "cos\t$params[3]\t$params[4]\t$params[5]\t$th\t$ct\n";



}

#
#
# Proper Dihedrals 
#

#Find Dih and get total number 
$npdih = 0;
for ($i= 0; $i < scalar(@buf); $i++) {
	if ($buf[$i] =~ /.*Proper Dih.:.*/) {
		$npdih = $buf[$i+1];
		$npdih =~ s/.*nr..//;
		chomp($npdih);
		$find = $i+3;
		last;
	}
}
#
# Process Dih and write them out.
#
# I'm assuming cosine
print OUT "DIHEDRALS \t $pdih\n";
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
	$params[3]++;
	$params[4]++;
	$params[5]++;
	$params[6]++;
	print OUT "cos\t$params[3]\t$params[4]\t$params[5]\t$params[6]\t$phi\t$cp\n";



}	
