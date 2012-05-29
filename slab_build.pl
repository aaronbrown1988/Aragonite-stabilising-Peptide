#!/usr/bin/perl


$a = 4.9614;
$b = 7.9671;
$c = 5.7404;

$imax = 24; #5;
$jmax = 15; #3;
$kmax = 3;# 2;

$cells = $imax *$jmax *$kmax;

$Nat = 20 * $cells;
$Nb = 12 * $cells;
$Nan = 12 * $cells;
$Nimp  = 4*$cells;




@ca = ("1.2375 0.675804 4.249322", "1.2375 3.304196 1.379322", "3.7125 4.655804 4.360678", "3.7125 7.284196 1.490678");

@c = ("1.2375 5.868908 3.3579", "1.2375 6.071092 0.4879", "3.7125 1.888908 5.2521", "3.7125 2.091092 2.3821");




#Annoying I've listed these backwards.... FOOL!
@o = ("4.815855 1.433596 2.37062","3.7125 3.367876 2.323265", "2.609145 1.433596 2.37062", "4.815855 2.546404 5.24062","3.7125 0.612124 5.193265","2.609145 2.546404 5.24062","2.340855 5.413596 0.49938","1.2375 7.347876 0.546448", "0.134145 5.413596 0.49938","2.340855 6.526404 3.36938","1.2375 4.592124 3.416735","0.134145 6.526404 3.36938");

my @at;
my @an;
my @b;
my $imp;


$Cat = 1;
$Cb = 1;
$Can = 1;
$Cimp = 1;



print "Lammps description\n";
print "\n";
print "$Nat atoms\n";
print "$Nb bonds\n";
print "$Nan angles\n";
print "$Nimp impropers\n";
print "5 atom types\n";
print "2 bond types\n";
print "2 angle types\n";
print "1 improper types\n";

print "\n";

$xhi = $imax * $a;
$yhi = $jmax * $b;
$zhi = $kmax * $c;
print "0.0 $xhi xlo xhi\n";
print "0.0 $yhi ylo yhi\n";
print "0.0 $zhi zlo zhi\n";
print "\n";

print "Masses\n\n";

print "\t1\t40.078  # Ca\n";
print "\t2\t12.000  # C\n";
print "\t3\t16.000  # O\n";
print "\t4\t16.000  # OW\n";
print "\t5\t1.000   # HW\n";

print "\n";



print "Atoms\n\n";


for ($i =0; $i < $imax; $i++ ) {
	for ($j = 0; $j < $jmax; $j++) {
		for ($k = 0; $k < $kmax; $k++) {
			$offset[0] = $i * $a;
			$offset[1] = $j * $b;
			$offset[2] = $k * $c;
			foreach $_ (@ca) {
				@coords = split(/\s+/, $_);
				$coords[0] += $offset[0];			
				$coords[1] += $offset[1];			
				$coords[2] += $offset[2];			
				print "\t$Cat\t0\t1\t2.00\t$coords[0]\t$coords[1]\t$coords[2] # Ca\n";
				$Cat++;
			}

			# Now for the Carbonates :S
			for ($n = 0; $n < 4; $n++) {
				@coords = split(/\s+/, $c[$n]);
				$coords[0] += $offset[0];			
				$coords[1] += $offset[1];			
				$coords[2] += $offset[2];			
				print "\t$Cat\t0\t2\t1.123\t$coords[0]\t$coords[1]\t$coords[2] # C\n";
				
				$throw = $Cat+1;
				$bond = "$Cat\t$throw";
				push(@b, $bond);
				$throw = $Cat+2;
				$bond = "$Cat\t$throw";
				push(@b, $bond);
				$throw = $Cat+3;
				$bond = "$Cat\t$throw";
				push(@b, $bond);

				
				# Angles 
				$throw = $Cat+1;
				$angle = $Cat+2;
				$angle = "$angle\t$Cat\t$throw";
				push(@an, $angle);
				$throw = $Cat+3;
				$angle = $Cat+2;
				$angle = "$angle\t$Cat\t$throw";
				push(@an, $angle);
				$throw = $Cat+1;
				$angle = $Cat+3;
				$angle = "$angle\t$Cat\t$throw";
				push(@an, $angle);

				#Impropers

				$throw = $Cat+1;
				$imp = $Cat+2;
				$bond = $Cat+3;
				$imp = "$imp\t$bond\t$Cat\t$throw";
				push(@imp, $imp);

				$Cat++;
				for ($nO = 0; $nO < 3; $nO++) {
					@coords = split(/\s+/, $o[11-$n*3-$nO]);
					$coords[0] += $offset[0];			
					$coords[1] += $offset[1];			
					$coords[2] += $offset[2];			
					print "\t$Cat\t0\t3\t-1.041\t$coords[0]\t$coords[1]\t$coords[2] # O\n";
					$Cat++;
	
				}
			}
		
		}
	}
}

print "\n";

print "Bonds\n\n";
for ($i = 0; $i < $Nb; $i ++) {
	@items = split(/\t+/, $b[$i]);
	print "\t$Cb\t1\t$items[0]\t$items[1] # C-O bond\n" ;
	$Cb++;
}
print "\n";
print "Angles\n\n";
for ($i = 0; $i < $Nan; $i ++) {
	@items = split(/\t+/, $an[$i]);
	print "\t$Can\t1\t$items[0]\t$items[1]\t$items[2] # O-C-O angle\n" ;
	$Can++;
}
print "\n";
print "Impropers\n\n";
for ($i = 0; $i < $Nimp; $i ++) {
	@items = split(/\t+/, $imp[$i]);
	print "\t$Cimp\t1\t$items[0]\t$items[1]\t$items[2]\t$items[3] # CO3 OOP\n" ;
	$Cimp++;
}




