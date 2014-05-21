#!/usr/bin/perl
local $| = 1;
my @buff;
my $x,$y,$z;
my $cryst;
my $title;
opendir(DH, "$ARGV[0]") || die "Couldn't open '$ARGV[0]': $!\n";
$n = 0;
while($file = readdir(DH)) {
	if ($file =~ /.*\.pdb/) {
		push(@files,$file);
		$n++;
	}
	
	#if ($n > 1000) { last;}
}
closedir(DH);
$total = scalar(@files);

mkdir "./complex";
mkdir "./complex/orig";
mkdir "./seperate";
$ncomplex = 0;
$nsep = 0;
open (LOG, ">filter.log") || die "Couldn't open log: $!\n";
for ($i = 0; $i < scalar(@files); $i++) {
	@buff = qw();
	$file = $files[$i];

	open(FH, "$ARGV[0]/$file") || die "Couldn't open a file I previously knew about? $ARGV[0]/$file: $!\n";
	print LOG "Processing file: $file";

	while ($line = readline(FH) ) {
		if ($line =~ /^CRYST.* /) {
			$cryst = $line;
			@params = split(/\s+/, $line);
			$x = $params[1]/2;
			$y = $params[2]/2;
			$z = $params[3]/2;
		} elsif ($line =~ /^TITLE.*/) {
			$title = $line;
		}elsif ($line =~ /^ATOM.*/) {
			push (@buff,$line);
		}
	}
	
	close(FH);
	$min = 9e99;	
	$max = -9e99;
	for($j = 0; $j < 511; $j++) {
		@params = split(/\s+/, $buff[$j]);
		for ($l = 511; $l < scalar(@buff); $l++) {
			@params2 = split(/\s+/, $buff[$l]);

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
			if( $min > $dist ) {
				$min = $dist;
				$min_atB = $l;
				$min_atA =$j
			}

			$max = ($max > $dist)? $max:$dist;

		}

	}
	print LOG " $min_atA -> $min_atB dist: $min";
	if ($min < 6) {
		#associated
		$ncomplex++;
		$throw = sqrt(($x)**2+($y)**2+($z)**2)/2;
		if ($max > sqrt(($x)**2+($y)**2+($z)**2)/2 ) {
			#move A to B;
			link("$ARGV[0]/$file", "./complex/orig/$file");	
			shuffle();
			print LOG ">>>>>>>Shuffling<<<<<< ";
		} else {
			link("$ARGV[0]/$file", "./complex/$file");	
		}


	} else {
		# disassociated
		link("$ARGV[0]/$file", "./seperate/$file");	
		$nsep++;
	}
	print LOG "\n";
	print "\b" x length($progress);
	$progress = "$i/$total";
	print "$progress";
}
$pcomplex = $ncomplex/($ncomplex+$nsep);
$psep = $nsep/($ncomplex+$nsep);

print LOG " Complex probability: $pcomplex\n"; 
print " Complex probability: $pcomplex\n"; 

close(LOG);

sub shuffle
{

	open(OH, ">./complex/$file") || die " Couldn't open ./complex/shuff_$file for writing:$!\n";	$ref = 0;
	local $i, $j;
	print OH "$cryst";
	print OH "$title";
	for ($i =1; $i < scalar(@buff); $i++) {
		@params = split(/\s+/, $buff[$i]);
		@params2 = split(/\s+/, $buff[$i-1]);
			if($params[4] != $params2[4] ) {
				$ref = $i;
#				print " USING $i as reference $params[4] != $params2[4]\n";
				next;
			}
			$dx = $params[6] - $params2[6];
			$dy = $params[7] - $params2[7];
			$dz = $params[8] - $params2[8];
			$flip = '';
			if ($dx**2 > $x**2) {
				if ($dx < 0 ) {
#					print "UP: $params[6] to";
					$params[6] += (2*$x);
#					print " $params[6]\n";
				} else {
					$params[6] = $params[6] - (2*$x);
#					print "DWN: $params[6]\n";
				}
				$flip = "$flip,x";
			}
			if ($dy**2 > $y**2) {
				if ($dy < 0 ) {
					$params[7] += (2*$y);
				} else {
					$params[7] = $params[7] - (2*$y);
				}
				$flip = "$flip,y";
			}
			if ($dz**2 > $z**2) {
				if ($dz < 0 ) {
					$params[8] += (2*$z);
				} else {
					$params[8] = $params[8] - (2*$z);
				}
				$flip = "$flip,z";
			}
			if ($flip ne '') {
#				print "moved $params[1]$params[2] $flip\n";
#	print "$buff[$i]\n";
				$res = sprintf  "%-6s%5d %4s %-3s %.1s%4d %11.3f%8.3f%8.3f%6.2f%6.2f %4s %2s %2s\n", $params[0],$params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$params[7],$params[8],$params[9],$params[10],$params[11],$params[12],$params[13],$params[14],"","",$params[15];
#	print "$res\n";
				$buff[$i] = $res;
				
			}
		


	}

	# Aggregate chainsc
	@params = split(/\s+/, $buff[$min_atA]);
	@params2 = split(/\s+/, $buff[$min_atB]);
	$dx = $params[6] - $params2[6];
	$dy = $params[7] - $params2[7];
	$dz = $params[8] - $params2[8];
	$fx = 0;
	$fy = 0;
	$fz = 0;
	if(($dx**2 > $x**2)) {
		$fx = ($dx > 0)? 1:-1;
	}
	if(($dy**2 > $y**2)) {
		$fy = ($dy > 0)? 1:-1;
	}
	if(($dz**2 > $z**2)) {
		$fz = ($dz > 0)? 1:-1;
	}
	$ref_chain =$params[4];
	$center = qw (0 0 0);
	$n = 0;
	for ($i=0; $i< scalar(@buff); $i++) {
		@params = split(/\s+/, $buff[$i]);
		if ($params[4] eq $ref_chain) {
			$center[0] += $params[6];
			$center[1] += $params[7];
			$center[2] += $params[8];
#			print OH "$buff[$i]"
			$n++;
			next;
		}
		$params[6] = $params[6] +($fx*2*$x);
		$params[7] = $params[7] +($fy*2*$y);
		$params[8] = $params[8] +($fz*2*$z);
		$center[0] += $params[6];
		$center[1] += $params[7];
		$center[2] += $params[8];
		$n++;
		$res = sprintf  "%-6s%5d %4s %-3s %.1s%4d %11.3f%8.3f%8.3f%6.2f%6.2f %4s %2s %2s\n", $params[0],$params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$params[7],$params[8],$params[9],$params[10],$params[11],$params[12],$params[13],$params[14],"","",$params[15];
		$buff[$i] = $res;

	}

	$center[0] = $center[0] / $n - $x;
	$center[1] = $center[1] / $n - $y;
	$center[2] = $center[2] / $n - $z;

	for ($i = 0; $i < scalar(@buff); $i++) {
		@params = split(/\s+/, $buff[$i]);
		$params[6] = $params[6] - $center[0];
		$params[7] = $params[7] - $center[1];
		$params[8] = $params[8] - $center[2];
		$res = sprintf  "%-6s%5d %4s %-3s %.1s%4d %11.3f%8.3f%8.3f%6.2f%6.2f %4s %2s %2s\n", $params[0],$params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$params[7],$params[8],$params[9],$params[10],$params[11],$params[12],$params[13],$params[14],"","",$params[15];
		print OH "$res";
	}

	
	print OH "TER\nENDMDL\n";
	close(OH);
}
