#!/usr/bin/perl
#
# Quick and dirty method for solvating something in LAMMPS
#

use Fcntl qw/:seek/;


$lmp_data = $ARGV[0];
my @tag;
my @type;
my @x, @y, @z;




open(GMX, "out.gro");
open(LMPDATA, "chain.lmp");
open(SOLV, ">chain.sol.lmp");


#Advance the file on 2 lines
readline(GMX);
$sol = readline(GMX); # number of solvent molecules


#Read in the water 

while ($line = readline(GMX)) {
	($rubbish,$a, $b,$c,$d, $e,$f) = split(/\s+/, $line);
	if ($f ne "") {
#		print "$line => $a, $b,$c,$d,$e,$f\n";
		push(@tag, $a);
		push(@type,$b);
		push(@x,($d*10));
		push(@y,($e*10));
		push(@z,($f*10));
	}
}



#Whizz down to the masses section 
while ($line = readline(LMPDATA)) {
		if ($line =~ /.*Masses.*/ ) {
			print "Found Masses section \n";
			last;
		}
}

while($line = readline(LMPDATA)) {
		if ($line =~ /.*HW.*/) {
			($rubbish, $lmp_h_type, $rubbish) = split(/\s+/, $line);
	#		print "$line => $rubbish, $lmp_h_type";
		}
		if ($line =~ /.*OW.*/) {
			($rubbish, $lmp_o_type, $rubbish) = split(/\s*/, $line);
		}
		
		if($line eq ""){last;}
		
}
print "H = $lmp_h_type \nO = $lmp_o_type\n";

seek LMPDATA, 0, SEEK_SET;

#Move on to the Atoms section
while ($line = readline(LMPDATA)) {
	print SOLV "$line";
	if($line =~ /.*Atoms.*/) {
		last;
	}
}

$line = readline(LMPDATA);

$xmin = 9999999;
$xmax = -$xmin;
$ymin = 9999999;
$zmin = 9999999;
$ymax = -$ymin;
$zmax = -$zmin;

while ($line = readline(LMPDATA)) {
		print SOLV "$line";
		if (length($line) < 3 ){ last;}
		($curratom, $currtag, $c,$d,$e,$f,$g) = split(/\s+/, $line);
	#	print "$curratom, $currtag, $c, $d, $e, $f, $g\n";
		$xmin = ($xmin > $e)? $e : $xmin;
		$xmax = ($xmax < $e)? $e : $xmax;
		$ymin = ($ymin > $f)? $f : $ymin;
		$ymax = ($ymax < $f)? $f : $ymax;
		$zmin = ($zmin > $g)? $g : $zmin;
		$zmax = ($zmax < $g)? $g : $zmax;
		
}

print "Slab bounds:\n";
print  "$xmin -> $xmax\n";
print  "$ymin -> $ymax\n";
print  "$zmin -> $zmax\n";

$curratom ++;

$last_atom = $curratom;

$prev_tag="";

$slab=0;

for ($i=0; $i<$sol; $i++) {
	if ($prev_tag ne $tag[$i]) {
		$prev_tag = $tag[$i];
		$currtag++;
	}
	$lmp_type = ($type[$i] eq "OW")? $lmp_o_type: $lmp_h_type;
	$charge = ($type[$i] eq OW)? -0.820000: 0.410000;
	
	$x[$i] += $xmin;
	$y[$i] += $ymin;
	$z[$i] += $zmax+0.2;
	
	
	#if (inslab($x[$i], $y[$i],$z[$i]) == 1) {
	##	print "$i @ ($x[$i],$y[$i],$z[$i]) is in the slab\n";
		#push(@exclude, $i);
		
		## Exclude the other atoms in that water molecule.
		#if ($i % 3 == 0) {
			#push(@exclude,$i+1);
			#push(@exclude, $i+2);
		#} elsif ($i %3 == 1) {
			#push(@exclude,$i-1);
			#push(@exclude,$i+1);
		#} elsif ( $i%3 == 2) {
			#push(@exclude,$i-1);
			#push(@exclude, $i-2);
		#}
		#$slab++;
	#} else {
		 print  SOLV "\t$curratom\t$currtag\t$lmp_type\t$charge\t$x[$i]\t$y[$i]\t$z[$i]\n";
		$curratom++;
	#}
}

print "$slab/$sol atoms found where we want our slab....\n";


print SOLV "\n";
# Move onto the bonds section
while ($line = readline(LMPDATA)) {
	print SOLV "$line";
	if($line =~ /.*Bonds.*/) {
		last;
	}
}

$line = readline(LMPDATA);
print SOLV "$line";

$currbond = 0;
while ($line = readline(LMPDATA)) {
		print SOLV "$line";
		if (length($line) < 3 ){ last;}
		($currbond, $rubbish2) = split(/\s+/, $line);
}
	
# Add Water bonds
$curratom = $last_atom;
for ($i =0; $i<$sol; $i+=3) {
	#if(inslab($x[$i], $y[$i], $z[$i]) == 0) {
		$currbond ++;
		$curratom = $last_atom +$i;
		$neigh = $curratom +1;
		print SOLV "\t$currbond\t2\t$curratom\t$neigh\n";
		$currbond ++;
		$neigh = $curratom +2;
		print SOLV "\t$currbond\t2\t$curratom\t$neigh\n";
	#}
}



print SOLV "Angles\n\n";
$curratom = $last_atom;
$currangle = 0;
for ($i = 0 ; $i < $sol; $i+= 3) {
	$currangle ++;
	$curratom = $last_atom+$i;
	$n1 = $curratom +1;
	$n2 = $curratom +2;
	print SOLV "\t$currangle\t2\t$n1\t$curratom\t$n2\n";
}


sub inslab()
{
	my $test = 0;
	$test = ($_[0] > $xmin);
	$test = $test && ($_[0] > $ymin);
	$test = $test && ($_[0] > $zmin);
	$test = $test && ($_[0] < $xmax);
	$test = $test && ($_[0] < $ymax);
	$test = $test && ($_[0] < $zmax);
	
	return ($test)
}
	
	
