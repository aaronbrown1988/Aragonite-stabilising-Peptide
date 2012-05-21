#!/usr/bin/perl

use POSIX;
use Chemistry::Mol; # PerlMol modules that make life simple
use Chemistry::File::PDB;


# Configuration
my $spc216= "/usr/share/gromacs/tutor/water/spc216.pdb";
my $wbx_l=18.6206; # Size of water box in A;
my $gap = 8; # Size of gap around solute;


$kc2ev = 0.04336;

#Water Parameters - SPC/FW
#$kb = 1059.162 * $kc2ev;
#$b0 = 1.0123;
#
#$cth = 75.9 * $kc2ev;
#$th0 = 113.24;
#$ub = 0;
#$cub = 0.0;

#$oeps = 0.1554253 * $kc2ev;
#$heps = 0;
#$osig = 3.1506;
#$hsig = 0;


#TIP3p
$kb = 1059.162 * $kc2ev;
$b0 = 0.9572;

$cth = 75.9 * $kc2ev;
$th0 = 104.52;
$ub = 0;
$cub = 0.0;

$oeps = 0.1521 * $kc2ev;
$heps = 0;
$osig = 3.1506;
$hsig = 0;



$owc = -0.82;
$hwc = 0.41;
$owm = 16;
$hwm = 1;


#
# Program below
#

my $owt, $hwt; # Water oxygen and hydrogen types
my $wa, $wb; # Water angle type water bond type
my $last_at, $last_b, $last_an, $last_a, $last_angt, $last_bt, $last_m; # last 
my $xlo, $xhi, $ylo, $yhi, $zlo, $zhi; 	# solute extreems 
my @water_origins; 			# Where we're going to start our 216 waters from
my @x,@y,@z; 				# positions of the atoms
my $i,$j,$k;

my $owm = 16;
my $hwm = 1;





open (INP, $ARGV[0]) || die "couldn't open $ARGV[0]\n";



# Find water types "OW HW"
# > Move to masses
while ($line = readline(INP)) {
	if ($line =~ /.*Masses.*/) {
		last;
	}
	if ($line =~ /.*atom types.*/) {
		($last_at, $throw) = split(/\s+/, $line);
	}
	if ($line =~ /.*atoms.*/) {
		($last_a, $throw) = split(/\s+/, $line);
	}
	if ($line =~ /.*bonds.*/) {
		($last_b, $throw) = split(/\s+/, $line);
	}
	if ($line =~ /.*angles.*/) {
		($last_ang, $throw) = split(/\s+/, $line);
	}
	if ($line =~ /.*bond types.*/) {
		($last_bt, $throw) = split(/\s+/, $line);
	}
	if ($line =~ /.*angle types.*/) {
		($last_angt, $throw) = split(/\s+/, $line);
	}
	
}

$line = readline(INP);
while ($line = readline(INP)) {
	if ($line =~ /.*OW.*/) {
		($throw,$owt,$throw) = split(/\s+/, $line);
	} elsif ($line =~ /.*HW.*/) {
		($throw, $hwt, $throw) = split (/\s+/, $line);
	} elsif (length($line) < 3) {
		last;
	}
}

# Read in atoms
while ($line = readline(INP)) {
	if ($line =~ /.*Atoms.*/) {
		last;
	}
}
$line = readline(INP);
while ($line = readline(INP)) {
	if (length($line) < 3) {
		last;
	}
	local @fields = split(/\s+/, $line);
	$xlo = ($fields[5] < $xlo) ? $fields[5] : $xlo;
	$ylo = ($fields[6] < $xlo) ? $fields[6] : $ylo;
	$zlo = ($fields[7] < $xlo) ? $fields[7] : $zlo;
	$xhi = ($fields[5] > $xhi) ? $fields[5] : $xhi;
	$yhi = ($fields[6] > $xhi) ? $fields[6] : $yhi;
	$zhi = ($fields[7] > $xhi) ? $fields[7] : $zhi;
	push(@x, $fields[5]);
	push(@y, $fields[6]);
	push(@z, $fields[7]);
	$last_m=$fields[2];
}

# Calculate how many water boxes we need

if($ARGV[1]) {
	
	$xlo = $ARGV[1];
	$xhi = $ARGV[2];
	$ylo = $ARGV[3];
	$yhi = $ARGV[4];
	$zlo = $ARGV[5];
	$zhi = $ARGV[6];

	$gap = 0;
}

$i = ceil(($xhi - $xlo + 2*$gap)/$wbx_l);
$j = ceil(($yhi - $ylo + 2*$gap)/$wbx_l);
$k = ceil(($zhi - $zlo + 2*$gap)/$wbx_l);


$i = ($i < 2)? 2: $i;
$j = ($j < 2)? 2: $j;
$k = ($k < 2)? 2: $k;
print "Tesselating with $i x $j x$k boxes\n";

if ($owt != undef) {
	to_section(section=> 'Bond Coeffs');
	while ($line = readline(INP)) {
		@fields = split(/\s+/, $line);
		$last_bt = $fields[0];
		if ($fields[3] eq "HW-OW" || $fields[3] eq "OW-HW") {
			last;
		}
	}
	to_section(section=> 'Angle Coeffs');
	while ($line = readline(INP)) {
		@fields = split(/\s+/, $line);
		$last_angt = $fields[0];
		if ($fields[5] eq "HW-OW-HW" ) {
			last;
		}
	}
}
	







# Prepare for output stage

seek(INP, 0,0);
open(OUT, ">$ARGV[0].sol") || die "Couldn't open output file";

#Write out up to masses section (We'll venutre back here to update the values);
while ($line = readline(INP)) {
	print OUT "$line";
	if ($line =~ /.*Masses.*/) {
		last;
	}
}
$line = readline(INP);
print OUT "$line";
while ($line = readline(INP)) {
	if (length($line) < 3) {
		last;
	} else {
		print OUT "$line";
	}
}

if ($owt == 0) {
	$owt = $last_at+1;
	print OUT "\t$owt\t$owm #OW\n";
	$hwt = $last_at+2;
	print OUT "\t$hwt\t$hwm #HW\n";
	$added = 1;
}
print OUT "$line";


if ($added == 1) {
	print "Adding in types\n";
	# Loop through and add bond and angle types

	$last_angt++;
	$last_bt++;

	to_section(section=>'Pair Coeffs', output=>1);
	fwd_section(output => 1);
	print OUT "\t$owt\t$oeps\t$osig #OW\n";
	print OUT "\t$hwt\t$heps\t$hsig #HW\n";
	print OUT "\n";

	to_section(section=>'Bond Coeffs', output=>1);
	fwd_section(output => 1);
	print OUT "\t$last_bt\t$kb\t$b0 #HW-OW\n";
	print OUT "\n";

	to_section(section=>'Angle Coeffs', output=>1);
	fwd_section(output => 1);
	print OUT "\t$last_angt\t$cth\t$th0\t$cub\t$ub # #HW-OW-HW\n";
	print OUT "\n";

}


# Move to atoms section
while($line = readline(INP)) {
	print OUT "$line";
	if($line =~/.*Atoms.*/) {
		last;
	}
}
print OUT "\n";
$line = readline(INP);
while ($line = readline(INP)) {
	if (length($line) < 3) {
		last;
	} else {
		print OUT "$line";
	}
}

$water = Chemistry::Mol->read($spc216);


my @offset;
my $a = $last_a;
for ($tmpx =0; $tmpx < $i; $tmpx ++) {
	for ($tmpy = 0; $tmpy < $j; $tmpy++) {
		for ($tmpz =0; $tmpz < $k; $tmpz ++) {
			$offset[0] = ($xlo)+$tmpx*$wbx_l;
			$offset[1] = ($ylo)+$tmpy*$wbx_l;
			$offset[2] = ($zlo)+$tmpz*$wbx_l;
			#$offset[0] = ($xlo-$gap+0.5*$wbx_l)+$tmpx*$wbx_l;
			#$offset[1] = ($ylo-$gap+0.5*$wbx_l)+$tmpy*$wbx_l;
			#$offset[2] = ($zlo-$gap+0.5*$wbx_l)+$tmpz*$wbx_l;
			
			foreach ($water->atoms) {
				$a++;
				@coords = $_->coords->array;
				$coords[0] += $offset[0];
				$coords[1] += $offset[1];
				$coords[2] += $offset[2];
				
				if (check(@coords)!= 0) {
					#Give it a little nudge :P
					$coords[0] += 0.1;
					$coords[1] += 0.1;
					$coords[2] += 0.1;
					
				}
				if ($_->symbol =~ /.*O.*/) {
					$last_m++;
					print OUT "\t$a\t$last_m\t$owt\t$owc\t$coords[0]\t$coords[1]\t$coords[2]\n";
				} else {
					print OUT "\t$a\t$last_m\t$hwt\t$hwc\t$coords[0]\t$coords[1]\t$coords[2]\n";
				}
			}
		
		}
	}
}

#Move to bonds
while($line = readline(INP)) {
	print OUT "$line";
	if($line =~/.*Bonds.*/) {
		last;
	}
}
print OUT "\n";
$line = readline(INP);
while ($line = readline(INP)) {
	if (length($line) < 3) {
		last;
	} else {
		print OUT "$line";
	}
}
$curr = $last_a+1;
for ($tmpx =0; $tmpx < $i; $tmpx ++) {
	for ($tmpy = 0; $tmpy < $j; $tmpy++) {
		for ($tmpz =0; $tmpz < $k; $tmpz ++) {
			for ($cur = 0; $cur < 216*3; $cur+= 3) {
				#if (($curh+1) > $a) {
					#$tmpx = $i;
					#$tmpy = $j;
					#$tmpz = $k;
					#last;
				#}
				$last_b++;
				$curh = $curr +1;
				print OUT "\t$last_b\t$last_bt\t$curr\t$curh\n";
				$curh = $curh +1;
				$last_b++;
				print OUT "\t$last_b\t$last_bt\t$curr\t$curh\n";
				$curr+=3;
				
			}
		}
	}
}



while($line = readline(INP)) {
	print OUT "$line";
	if($line =~/.*Angles.*/) {
		last;
	}
}
print OUT "\n";
$line = readline(INP);
while ($line = readline(INP)) {
	if (length($line) < 3) {
		last;
	} else {
		print OUT "$line";
	}
}
$curr = $last_a+1;
for ($tmpx =0; $tmpx < $i; $tmpx ++) {
	for ($tmpy = 0; $tmpy < $j; $tmpy++) {
		for ($tmpz =0; $tmpz < $k; $tmpz ++) {
			for ($cur = 0; $cur < 216*3; $cur+= 3) {
				$last_ang++;
				$curh = $curr +1;
				$curh2 = $curh+1;
				#if ($curh2 > $a) {
					#$tmpx = $i;
					#$tmpy = $j;
					#$tmpz = $k;
					#last;
				#}
				print OUT "\t$last_ang\t$last_angt\t$curh\t$curr\t$curh2\n";
				$curr += 3;
			}
		}
	}
}

while (!eof(INP)) {
	$line = readline(INP);
	print OUT "$line";
}

print "$a atoms\n";
print "$last_ang angles\n";
print "$last_b bonds\n";

if ($added == 1) {
	print "$hwt atom types\n";
	print "$last_bt  bond types\n";
	print "$last_angt angle types\n";
}



sub to_section {
	%params = @_;
	local $line;
	while ($line = readline(INP)) {
		if (defined($params{output})) {
			print OUT "$line";
		}
		if ($line =~/.*$params{section}.*/) {
			last;
		}
	}
	$line = readline(INP);
	if (defined($params{output})) {
		print OUT "$line";
	}

}

sub fwd_section {
	%params = @_;
	local $line;
	while ($line = readline(INP)) {
		if (length($line) < 3) {
			last;
		} elsif (defined($params{output})) {
			print OUT "$line";
		}
	}
}


sub check {
	my $i;
	my $dist;
	@coords = @_;
	$close = 0;
	for($i = 0; $i < $last_a; $i++) {
		$dist = 0;
		$dist = ($x[$i] - $coords[0])**2;
		$dist += ($y[$i] - $coords[1])**2;
		$dist += ($z[$i] - $coords[2])**2;
		$dist = sqrt($dist);
		#print "$dist \n";
		
		if ($dist <= 0.2) {
			$close = 1;
		}
	}
	return ($close);
		
}

close(INP);
if ( -e 'suggested.inp') {
	open(INP, '+<suggested.inp') || die "couldn't open suggested.inp for modifying: $!\n";
	@suggested = <INP>;
	seek(INP,0,0);
	foreach $line (@suggested) {
		print INP $line;
		if ($line =~ /.*minimize.*/) {
			print INP "fix 1 all shake 0.001 10 0 b $last_bt\n";
		}
	}
	truncate(INP, tell(INP));
	close(INP);
}
