#!/usr/bin/perl
local $| = 1;
use threads;
use threads::shared;
use POSIX qw(floor);
my @threads;
my @files :shared;
my @hist :shared;
my @avg :shared;
my $progress :shared;
my $done :shared;
my @avg_frames :shared;
my @min_frames :shared;
my %region :shared;
my @residue :shared;
my %residue_pairs :shared;


for ($i = 0; $i <= 30; $i++) {
	for ($j = $i; $j <= 30; $j ++ ) {
		$residue_pairs{"$i $j"} = 0;
	}
}

for ($i =0; $i <= 30; $i++) {
	$residue[$i] = 0;
}

for ($i = 0; $i < 60; $i++ ) {
	$hist[$i] = 0;
	$avg[$i] = 0;
	$min_frames[$i] = "";
	$avg_frames[$i] = "";
}
$region{'1 1'} = 0;
$region{'1 2'} = 0;
$region{'1 3'} = 0;
$region{'1 4'} = 0;
$region{'2 1'} = 0;
$region{'2 2'} = 0;
$region{'2 3'} = 0;
$region{'2 4'} = 0;
$region{'3 1'} = 0;
$region{'3 2'} = 0;
$region{'3 3'} = 0;
$region{'3 4'} = 0;
$region{'4 1'} = 0;
$region{'4 2'} = 0;
$region{'4 3'} = 0;
$region{'4 4'} = 0;


opendir(DH, "$ARGV[0]") || die "Couldn't open $ARGV[0] to read files: $!\n";

while ($line = readdir(DH)) {
	if ($line =~ /.*\.pdb/) {
		push (@files,$line);
		$n++;
	}
#	if ($n >= 10) { last; }
}
closedir(DH);
$i = scalar(@files);
print "$i files $n\n";

for ($i= 0; $i < 4; $i++) {
	$threads[$i] = threads->create('process', $ARGV[0]);
}


for ($i=0; $i < 4; $i++) {
	$threads[$i]->join();
}

print "\b" x length($progress);

#Output Histogram
open (HIST, ">sep_hist.xvg") || die "Couldn't open sep_hist.xvg for writing: $!\n";
for ($i = 0; $i < scalar(@avg); $i++) {
	print HIST "$i\t$hist[$i]\t$avg[$i]\n";
}
close(HIST);



# Output a log of what we put where
open(LOG, ">seperation.log") || die "Couldn't open seperation.log for writing\n";

print LOG " AVERAGE distances\n";
print LOG "Dist\tFrames\n";
for ($i = 0; $i < scalar(@avg); $i++) {
	if ($avg[$i] == 0) {
		next;
	}
	print LOG "$i\t$avg_frames[$i]\n";
}
print LOG '-' x 80;
print LOG "\n Min Distances\n";
print LOG "Dist\tFrames\n";
for ($i = 0; $i < scalar(@hist); $i++) {
	if ($hist[$i] == 0) {
		next;
	}
	print LOG "$i\t$min_frames[$i]\n";
}
print LOG '-' x 80;
print LOG "\nREGION\n";
print LOG "Region\tCount\n";
foreach $_ (keys(%region)) {
	print LOG "$_\t$region{$_}\n";
}

close(LOG);

open(R_HIST, ">residue_hist.xvg") || die " Couldn't open residue_hist.xvg\n";
for ($i = 0; $i < @residue; $i++) {
	print R_HIST "$i\t$residue[$i]\n";
}
close(R_HIST);


open (R_PAIR, ">residue_pairs.tsv") || die "Couldn't open residue_pairs.tsv\n";
 
@order = sort {$residue_pairs{$b} <=> $residue_pairs{$a}} keys %residue_pairs;

for ($i = 0; $i < @order; $i++) {
	$a = $order[$i];
	if ($residue_pairs{$a} != 0) {
		print R_PAIR "$a,\t$residue_pairs{$a}\n";
	}
}
close(R_PAIR);
		



sub process
{
	my $path = @_[0];
	my $id = threads->tid();
	my $i,$j,$k,$line;
	my @buff;
	my @params;
	my $nfiles = scalar(@files);
	my $x, $y, $z, $dx,$dy,$dz, $dist,$n;
	my $line;
	my $min = 1e99;
	my $amin = 1e99;
	my $avg = 0;
	my $refchain = 'A';
	my $chain = 'B';
	my $min_r1 = 0;
	my $min_r2 = 0;



#	print "$id Running with $nfiles found\n";
	for ($i = $id-1; $i < $nfiles; $i += 4) {

		#Read file into Local Buffer
		open (FH, "$path/$files[$i]") || die "Couln't open $path/$files[$i]: $!\n"; 	
		while ($line = readline(FH)) {
			if ($line =~ /^CRYST.*/) {
				@params = split(/\s+/, $line);
				$x = $params[1]/2;
				$y = $params[2]/2;
				$z = $params[3]/2;
			} elsif ($line =~ /^ATOM.*/) {
				push (@buff,$line);
			}
		}
		close(FH);
		$l = $files[$i];
		$l =~ s/\.pdb//;
		$n = 0;
		$min = 1e99;
		for ($j = 0; $j < 511; $j++) {
			@params = split(/\s+/, $buff[$j]);
			if ($params[2] !~ /\b(CA|C|N)\b/) {
				next;
			}
			$n++;
			$amin = 1e99;
			for ($k=511; $k < scalar(@buff); $k++) {
				@params2 = split(/\s+/, $buff[$k]);
				
				if ($params2[2] !~ /\b(CA|C|N)\b/) {
					next;
				}
				$dx = $params[6] - $params2[6];
				$dy = $params[7] - $params2[7];
				$dz = $params[8] - $params2[8];

				$dx = ($dx**2 > $x**2)? (abs($dx)-(2*$x)):$dx;
				$dy = ($dy**2 > $y**2)? (abs($dy)-(2*$y)):$dy;
				$dz = ($dz**2 > $z**2)? (abs($dz)-(2*$z)):$dz;
																						
				$dist = ($dx)**2;
				$dist += ($dy)**2;
				$dist += ($dz)**2;
																														
				$dist = sqrt($dist);

				if ($amin > $dist) {
					$amin = $dist;
					$min_r2 = $params2[5];
				}
			}
			if ($min > $amin) {
				$min = $amin;
				$min_r1 = $params[5];
			}
			$avg += $amin;
		}
		if ($min > 6) {
			next;
		}

		#Residue Hist
		{lock (@residue);
			$residue[$min_r1] = $residue[$min_r1]+1;
			$residue[$min_r2] = $residue[$min_r2]+1;
		}
		# Residue Pairings
		if ($min_r1 <= $min_r2) {
			lock (%residue_pairs);
			$residue_pairs{"$min_r1 $min_r2"} ++;
		} else {
			lock (%residue_pairs);
			$residue_pairs{"$min_r2 $min_r1"}++;
		}

		#Region distribution
		if ($min_r1 < 8 ) {
			$min_r1 = 1;
		} elsif($min_r1 <= 16) {
			$min_r1 = 2;
		} elsif($min_r1 <= 23) {
			$min_r1 = 3;
		} else {
			$min_r1= 4;
		}

		if ($min_r2 < 8 ) {
			$min_r2 = 1;
		} elsif($min_r2 <= 16) {
			$min_r2 = 2;
		} elsif($min_r2 <= 23) {
			$min_r2 = 3;
		} else {
			$min_r2= 4;
		}


#		if ($min_r2 < $min_r1) {
#			$j = $min_r1;
#			$min_r1 = $min_r2;
#			$min_r2 = $j;
#		}
		{lock(%region);
			$region{"$min_r1 $min_r2"} ++; }
		

		#Average backbone distance Histogram
		$min = floor($min);
		$min = ($min > 59)? 59:$min;
		if ($n != 0 ) {
			$avg = floor($avg/$n); 
			$avg = ($avg > 59)? 59:$avg;
		 	lock(@avg);
			$avg[$avg]++; 
		}
		
		#average distance frame list
		{lock (@avg_frames); $avg_frames[$avg] = "$avg_frames[$avg] $l";}
		#Min distance frame list
		{lock (@min_frames); $min_frames[$min] = "$min_frames[$min] $l";}
		

		#Minimum distance Histogram
		{lock(@hist);
		$hist[$min]++; }

		undef(@buff);
		print "\b" x length($progress);
		$done++;
		$progress = "$done/$nfiles";
		print "$progress";
	}

}


