#!/usr/bin/perl

use POSIX;
use Chemistry::Mol; # PerlMol modules that make life simple
use Chemistry::File::PDB;


# Configuration
my $spc216= "/usr/share/gromacs/tutor/water/spc216.pdb";
my $wbx_l=18.6206; # Size of water box in A;
my $gap = 5; # Size of gap around solute;

#
# Program below
#

my $owt, $hwt; # Water oxygen and hydrogen types
my $wa, $wb; # Water angle type water bond type
my $last_at, $last_b, $last_an, $last_a, $last_angt, $last_bt; # last 
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

$i = ceil(($xhi - $xlo + 2*$gap)/$wbx_l);
$j = ceil(($yhi - $ylo + 2*$gap)/$wbx_l);
$k = ceil(($zhi - $zlo + 2*$gap)/$wbx_l);


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
	print OUT "\t$last_at\t$owm\n";
	$hwt = $last_at+2;
	print OUT "\t$last_at\t$hwm\n";
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
	print OUT "\t$owt\t$osig\t$oeps #OW\n";
	print OUT "\t$hwt\t$hsig\t$heps #HW\n";
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
			$offset[0] = ($xlo-$gap)+$tmpx*$wbx_l;
			$offset[1] = ($ylo-$gap)+$tmpy*$wbx_l;
			$offset[2] = ($zlo-$gap)+$tmpz*$wbx_l;
			
			foreach ($water->atoms) {
				$a++;
				@coords = $_->coords->array;
				$coords[0] += $offset[0];
				$coords[1] += $offset[1];
				$coords[2] += $offset[2];
				if ($_->symbol =~ /.*O.*/) {
					$last_m++;
					print OUT "\t$a\tMOL\t$hwt\t$hwc\t$coords[0]\t$coords[1]\t$coords[2]\n";
				} else {
					print OUT "\t$a\tMOL\t$owt\t$owc\t$coords[0]\t$coords[1]\t$coords[2]\n";
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
$curr = $last_a;
for ($tmpx =0; $tmpx < $i; $tmpx ++) {
	for ($tmpy = 0; $tmpy < $j; $tmpy++) {
		for ($tmpz =0; $tmpz < $k; $tmpz ++) {
			for ($cur = 0; $cur < 216*3; $cur+= 3) {
				$last_b++;
				$curr++;
				$curh = $curr +1;
				print OUT "\t$last_b\t$last_bt\t$curr\t$curh\n";
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
$curr = $last_a;
for ($tmpx =0; $tmpx < $i; $tmpx ++) {
	for ($tmpy = 0; $tmpy < $j; $tmpy++) {
		for ($tmpz =0; $tmpz < $k; $tmpz ++) {
			for ($cur = 0; $cur < 216*3; $cur+= 3) {
				$last_ang++;
				$curr++;
				$curh = $curr +1;
				$curh2 = $curh+1;
				print OUT "\t$last_ang\t$last_angt\t$curh\t$curr\t$curh2\n";
			}
		}
	}
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
