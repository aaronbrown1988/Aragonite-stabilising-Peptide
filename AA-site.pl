#!/usr/bin/perl
#
#
# Map interaction site to closest CG Bead and give the angle between the chain 
#
# USAGE: AA-site.pl FOLDER_OF_PDBS AA SURF_RES
use Math::Vector::Real;
use POSIX;
my @hist;
my @histX;
my @histY;
my %interaction;
my %sites = (
		ALA => 'CB',
		ARG => 'CZ',
		ASN => 'ND2',
		ASP => 'CG',
		GLN => 'N',
		GLU => 'CG',
#		GLY => 'CA', # Pulled this one out as CA->CA is not a valid vec.
		CYS => 'SG',
		HIS => 'COM',
		ILE => 'CD',
		LEU => 'CD',
		LYS => 'NZ',
		MET => 'S',
		PRO => 'CG',
		PHE => 'COM',
		SER => 'OG',
		THR => 'O',
		TRP => 'COM',
		TYR => 'COM',
		VAL => 'CB'
		);
for ($i = 0; $i <=180; $i++) { $hist[$i]=0; $histY[$i]=0; $histX[$i]=0;}

opendir(DH, "$ARGV[0]") || die "couldn't open $ARGV[0]:$! \n";
while ($file = readdir(DH)) {
	if ($file =~ /^[0-9]+\.pdb/) {
		push (@files,$file);
	}
}
close(DH);

open(AT, ">$ARGV[1]-ang.tsv");

foreach $file (@files) {
	process($file);
}



# Main Processing Sub routine
sub process {
	$filename = $_[0];
	open(FH, "$ARGV[0]/$filename") || die "Couldn't open $ARGV[0]/$filename :$!\n";
	my @slab;
	my @aa;
	while ($line = readline(FH)) {
		#Split lines from pdb into atoms in the slab and atoms in the residue
		if ($line =~/.*$ARGV[2].*/) {
			push (@slab, $line);
		} elsif ($line =~ /.*$ARGV[1].*/) {
			push (@aa, $line);
		}
	}
	close(FH);

	if (scalar(@slab) == 0 || scalar(@aa) == 0) {
		die "Failed to find slab or aa $ARGV[2] $ARGV[1]\n";
	} 
	#print STDERR scalar(@slab),scalar(@aa);

	my @ep;
	my $ca;
	if ($sites{$ARGV[1]} eq "COM" ) {

		foreach $at (@aa) {
			@params = split(/\s+/, $at);
			if ($params[2] =~ /.*C[DGEZ].*/) {
				$ep[0] += $params[6];
				$ep[1] += $params[7];
				$ep[2] += $params[8];
				$n++;
			} elsif ($params[2] eq "CA" ) {
				$ca[0] = $params[6];
				$ca[1] = $params[7];
				$ca[2] = $params[8];
			}
		}
		$ep[0] /= $n;
		$ep[1] /= $n;
		$ep[2] /= $n;
	} else {
		foreach $at (@aa) {
			@params = split (/\s+/, $at);
			if ($params[2] eq $sites{$ARGV[1]}) {
				$ep[0] = $params[6];
				$ep[1] = $params[7];
				$ep[2] = $params[8];
			} elsif ($params[2] eq "CA" ) {
				$ca[0] = $params[6];
				$ca[1] = $params[7];
				$ca[2] = $params[8];
			} elsif ($params[2] eq "N" ) {
				$n[0] = $params[6];
				$n[1] = $params[7];
				$n[2] = $params[8];
			} elsif ($params[2] eq "C") {
				$c[0] = $params[6];
				$c[1] = $params[7];
				$c[2] = $params[8];

			}

		}
	}
#print STDERR "Site: @ep\t CA:@ca\n";

	$NCV = V(($n[0]+$c[0])/2, ($n[1]+$c[1])/2, ($n[2]+$c[2])/2);
	$CaV = V($ca[0], $ca[1], $ca[2]);
	$a = $CaV - $NCV;
	print AT "$filename\t";
	# Dot product with the chain direction.
	$dot = $a * V(0,0,1);
	$dot = acos($dot / abs($a));
	$dot = $dot * 57.3;
	$filename =~ s/\.pdb//;
	print AT "$dot\t";
	$dot = floor($dot+ 0.5);
	$hist[$dot] ++;
	#print STDERR "$filename $dot \n";
	#dot production with the 100 direction
	# Dot product with the chain direction.
	$dot = $a * V(1,0,0);
	$dot = acos($dot / abs($a));
	$dot = $dot * 57.3;
	$filename =~ s/\.pdb//;
	print AT "$dot\t";
	$dot = floor($dot+ 0.5);
	$histX[$dot] ++;
	#dot production with the 010 direction
	$dot = $a * V(0,1,0);
	$dot = acos($dot / abs($a));
	$dot = $dot * 57.3;
	$filename =~ s/\.pdb//;
	print AT "$dot\n";
	$dot = floor($dot+ 0.5);
	$histY[$dot] ++;

	# Loop through and find the closest atom
	my $mindist = 9e99;
	my $minres = 9e99;
	my $minat = 9e99;
	my $minatname = 9e99;
	my @minatcoord = qw(9e99 9e99 9e99);

	for ($i = 0; $i < scalar(@slab); $i ++) {
		@params = split(/\s+/, $slab[$i]);
		if ($params[2] =~ /H.*/) {
			#skip Hydrogens
			next;
		}
		$dist = ($params[6] - $ep[0])**2;
		$dist += ($params[7] - $ep[1])**2;
		$dist += ($params[8] - $ep[2])**2;
		$dist = sqrt($dist);
		if ($dist < $mindist) {
			$mindist = $dist;
			$minres = $params[3];
			$minat = $i;
			$minatname = $params[2];
			$minatcoord[0] = $params[6];
			$minatcoord[1] = $params[7];
			$minatcoord[2] = $params[8];
		}
	}
	#print STDERR "$filename $minatname \n";
	$interaction{$minatname} ++;
}
$total = 0;
open (OF, ">$ARGV[1]-sites.tsv");
foreach $_ (keys(%interaction)) {
	$interaction{$_} /= (scalar(@files) /100);
	$total += $interaction{$_};
	print OF "$_\t$interaction{$_}\n";
}

$com = $interaction{'C1'};  
$com += $interaction{'C2'};  
$com += $interaction{'C3'};  
$com += $interaction{'C4'};  
$com += $interaction{'C5'};  
$com += $interaction{'O5'};  

close(AT);
print OF "X\t$com\n";
close(OF);
open (OF, ">$ARGV[1]-hist.tsv");
for($i = 0; $i <=180; $i++) {
	$hist[$i] /= scalar(@files);
	$histX[$i] /= scalar(@files);
	$histY[$i] /= scalar(@files);
	print OF "$i\t $hist[$i]\t$histX[$i]\t$histY[$i]\n";
}
close(OF);
$up = 0;
for ($i = 0; $i < 90; $i++) {
	$up += $hist[$i];
}
$up /= scalar(@files);
print "Up: $up\n";

