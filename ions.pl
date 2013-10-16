#!/usr/bin/perl
#
# Calculates the distance between the peptide and ions
# usage ion-dist traj.pdb

use POSIX;

open(FH, "$ARGV[0]") || die " Couln't open $ARGV[0] for reading: $!\n";
open(MINT, ">ion-min.tsv") || die "Couldn't open ion-min.tsv for writing: $!\n";
open(AVGT, ">ion-avg.tsv") || die " Couldn't open ion-avg.tsv for writing: $!\n";
open(HIST, ">ion-hist.tsv") || die "Couldn't open ion-hist for writing:$!\n";
open(FULL, ">ion-raw.tsv") || die "Couldn't open ion-raw.tsv for writing: $!\n";
open(CONT, ">ion-contact.tsv") || die "Couldn't open ion-contact.tsv for writing: $!\n";

print AVGT "# Time\tCA\tCL\tCLW\n";
print MINT "# Time\t minimum Distance\tPair\n";
for ($j = 0; $j < 100; $j++) {
	$hist{CA}[$j] = 0;
	$hist{CL}[$j] = 0;
	$hist{CLW}[$j] = 0;
	$hist{all}[$j]=0;
}
$ca_bound =0;
$cont_tot = 0;
while ($line = readline(FH)) {
	@ions = qw();
	@peptide = qw();
	while ($line !~ /ENDMDL.*/) {
		if ($line =~ /CRYST1.*/) {
	   		@params = split(/s+/, $line);
			$bx = $params[1]/2;
			$by = $params[2]/2;
			$bz = $params[3]/2;
	 	} elsif ($line =~ /ATOM.*/) {
			chomp($line);
			@params = split(/\s+/,$line);
			if ($params[3] =~ /C[AL].*/) {
				push (@ions, $line);
			} else {
				push (@peptide, $line);
			}
	  	} elsif ($line =~ /TITLE.* t=.*/) {
			$line =~ s/.*t=\s+//;
			chomp($line);
			$time = $line;
		}
		$line = readline(FH);
	}
	$mindist = 1e99;
	$avg{CA} = 0;
	$avg{CL} = 0;
	$avg{CLW} = 0;
	$n{CA} =0;
	$n{CL} = 0;
	$n{CLW}=0;
	$min_res=0;
	print FULL "$time";
	$ca = 0;
	for($i = 0; $i < @ions; $i++) {
		@ip = split(/\s+/, $ions[$i]);
		$my_min = 1e99;
		for ($j = 0; $j < @peptide; $j++) {
			@pp = split(/\s+/, $peptide[$j]);
			$dx = $ip[5] - $pp[5];
			$dy = $ip[6] - $pp[6];
			$dz = $ip[7] - $pp[7];

			$dx = ($dx**2 > $bx**2)? (abs($dx)-(2*$bx)): $dx;
			$dy = ($dy**2 > $by**2)? (abs($dy)-(2*$by)): $dy;
			$dz = ($dz**2 > $bz**2)? (abs($dz)-(2*$bz)): $dz;

			$dist = $dx**2 + $dy**2 + $dz**2;
			$dist = sqrt($dist);


			if($mindist > $dist) {
				$mindist = $dist;
				$minpair = "$ip[2]:$ip[1] - $pp[1]:$pp[2]$pp[3]$pp[4]";
			
			}
			if($my_min > $dist) {
				$my_min = $dist;
				$min_res = $pp[4];
			}
		}
		if ($my_min == 1e99) {
				
			die "Something went wrong? Never found anything for $i $j\n";
#	next;
		}
		$avg{$ip[3]} += $my_min;
		$n{$ip[3]} ++;
		$my_min = ceil($my_min);
		if($my_min < 5) {$res{$ip[3]}[$min_res] ++; $ca=1; $cont_tot++;}
#	print "$my_min\n";
		print FULL "\t$my_min\tX$min_res";
		if ($my_min > 99) { $my_min = 99;}
		$hist{$ip[3]}[$my_min-1]++;
		$hist{all}[$my_min-1]++;

	}
	print FULL "\n";
	$avg{CA} /= $n{CA};
	$avg{CL} /= $n{CL};
	$avg{CLW} /= $n{CLW};
	print MINT "$time\t$mindist\t$minpair\n";
	print AVGT "$time\t$avg{CA}\t$avg{CL}\t$avg{CLW}\n";
	if($ca==1) {$ca_bound++;}


}
for($i = 1; $i <= 100; $i++ ) {
	print HIST "$i\t$hist{CA}[$i-1]\t$hist{CL}[$i-1]\t$hist{CLW}[$i-1]\t$hist{all}[$i-1]\n";
}
for ($i = 0; $i < @ions; $i++) {
	@params = split(/\s+/, $ions[$i]);
	print FULL "@ s$i legend \"$params[1]$params[3]\"\n";
}
for ($i = 1; $i <= 30; $i++) {

	$res{CA}[$i] = $res{CA}[$i]/ $cont_tot;
	$res{CLW}[$i] = $res{CLW}[$i] /$cont_tot;
	$res{CL}[$i] = $res{CL}[$i] / $cont_tot;

	$res{CA}[$i] = ($res{CA}[$i] eq "")? 0 :$res{CA}[$i];
	$res{CLW}[$i] = ($res{CLW}[$i] eq "")? 0 :$res{CLW}[$i];
	$res{CL}[$i] = ($res{CL}[$i] eq "")? 0 :$res{CL}[$i];
	print CONT "$i\t$res{CA}[$i]\t$res{CL}[$i]\t$res{CLW}[$i]\n";
}
print "#Frames with 1 or more CA bound: $ca_bound\n";
close(FH);
close(HIST);
close(AVGT);
close(MINT);
close(FULL);
close(CONT);

