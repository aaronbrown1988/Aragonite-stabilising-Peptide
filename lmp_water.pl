#!/usr/bin/perl
#
# Generate a Water box in lammps
#
#

use POSIX;

#SPC-FW 
$kb = 1059.162;
$roh = 1.0123;
$ka = 75.9;
$th_hoh = 113.24;
$eps_oo = 0.1554253;
$sig_oo = 3.1506;
$eps_hh = 0;
$q_o = -0.82;
$q_h = 0.41;



print "LAMMPS description\n";
print "648 atoms\n";
print "432 bonds\n";
print "2 atom types\n";
print "1 bond types\n";
print "1 angle types\n";
print "\n";
print "-1 2 xlo xhi\n";
print "-1 2 ylo yhi\n";
print "-1 2 zlo zhi\n";

print "\n\nMasses\n\n";
print "\t1\t16\n";
print "\t2\t1\n";

#my $x = @ARGV[1];
#my $y = @ARGV[2];
#my $z = @ARGV[3];

print "\nPair Coeffs\n\n";
print "\t1\t$sig_oo\t$eps_oo\n";
print "\t2\t0.0\t0.0\n";

print "\nBond Coeffs\n\n";
print "\t1\t$kb\t$roh\n";

print "\nAngle Coeffs\n\n";
print "\t1\t$ka\t$th_hoh\n";





print "\nAtoms\n\n";
$atom = 1;
for ($i =1; $i <= 216; $i++) {
	$x = rand() *1.7;
	$y = rand()*1.7;
	$z = rand()*1.7;
	print "\t$atom\t$i\t1\t$q_o\t$x\t$y\t$z\n";
	$atom++;
	$hx = $x + cos(50);
	$hy = $y + sin(50);
	print "\t$atom\t$i\t2\t$q_h\t$hx\t$hy\t$z\n";
	$atom++;
	$hx = $x + cos(50);
	$hy = $y - sin(50);
	print "\t$atom\t$i\t2\t$q_h\t$hx\t$hy\t$z\n";
	$atom++;
}
	
print "\nBonds\n\n";
$bond = 1;
for ($i =1; $i <= 3*216; $i+=3) {
	$ah = $i+1;
	$bh = $i+2;
	print "\t$bond\t1\t$i\t$ah\n";
	$bond++;
	print "\t$bond\t1\t$i\t$bh\n";
}

