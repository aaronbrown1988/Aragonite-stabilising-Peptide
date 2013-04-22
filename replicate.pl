#!/usr/bin/perl
#
# Due to genconf sucking. I've rewritten this to take into account chains
# Once and for all.
# CAVEAT: Assumes chains direction is Z
# usage unit.pdb X Y Z 

$iCurChain = 1;
$iCurRes = 1;

$curRes = 1;
$curChain = 1;
$curAt = 1;
$nr = -1;
$xrep = $ARGV[1];
$yrep = $ARGV[2];
$zrep = $ARGV[3];
$alt = $ARGV[4];


my $a,$b,$c;

open(UNIT, $ARGV[0]) || die "Couldn't open unit cell $ARGV[0]: $!\n";

open(REP, ">rep.pdb") || die "Couldn't open rep.pdb for writing: $!\n";


#Read first line 
$line = readline(UNIT);
if ($line =~ /.*CRYST.*/) {
	@params = split(/\s+/, $line);
	$a = $params[1];
	$b = $params[2];
	$c = $params[3];
	$params[1] *= $xrep;
	$params[2] *= $yrep;
	$params[3] *= $zrep;
	#print REP "@params\n";
	printf REP "%6s%9.3f%9.3f%9.3f%7.2f%7.2f%7.2f%10s%3d\n", $params[0],$params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$params[7],$params[8];
}
@buf = qw();
while ($line = readline(UNIT)) {
	@params = split(/\s+/, $line);
	if ($params[4] == $iCurChain ) {
		$nr = $params[5];
		push(@buf,$line);
	} else {
		print "$params[4]!=$iCurChain: nr: $nr   line $line";
		rep();
		@params = split(/\s+/, $line);
		$iCurChain = $params[4];
		@buf = qw();
		push(@buf, $line);
		#$curChain++;
	#	$curRes = 1;
		$iCurRes=1;
	}
}

sub rep
{
	print " iCurChain: $iCurChain ALT:$alt\n";
	if ($alt == 1 && ((-1)** $iCurChain) > 0 ) {
		$curRes--;
	} #else {
#		$curRes++;
#}
	for ($i = 0; $i < $xrep; $i++) {
		for ($j = 0; $j < $yrep; $j++) {
			if ($alt == 1 && ((-1)** $iCurChain) < 0 ) {
				$curRes += ($nr * $zrep) ;
				print " iCurChain: $iCurChain\n";
#				$curRes = 1;
			}
			for ($k =0; $k < $zrep; $k++ ) {
				for($l = 0; $l < @buf; $l++ ) {
					if ($alt == 1 && (((-1)** $iCurChain)< 0)) {
					@params  = split(/\s+/, $buf[scalar(@buf)-1-$l]);
					} else {
					@params  = split(/\s+/, $buf[$l]);
					}
					$params[4] = $curChain;
					if ($alt == 1 && (((-1)** $iCurChain)< 0) && $params[5] != $iCurRes) {
						$curRes--;
#						$curRes++;
						$iCurRes = $params[5];
							
					}elsif ($params[5] != $iCurRes) {
						$curRes++;
						$iCurRes = $params[5];
					}
					$params[5] = $curRes;
					$params[6] += $i*$a;
					$params[7] += $j*$b;
					$params[8] += $k*$c;
					$params[1] = $curAt;
					$curAt++;
#					print REP "@params\n";
					printf REP "%-6s%5d%4s  %-3s %.1s%4d %11.3f%8.3f%8.3f%6.2f%6.2f %4s %2s %2s\n", $params[0],$params[1],$params[2],$params[3],$params[4],$params[5],$params[6],$params[7],$params[8],$params[9],$params[10],$params[11],$params[12],$params[13],$params[14],"","",$params[15];
				}
			}
			if ($alt == 1 && ((-1)** $iCurChain) < 0 ) {
				$curRes += (($nr * $zrep) );
				
			}
			if($alt ==1 && !(((-1)**$iCurChain) < 0)) {
				$curRes++;
			}
			if ($alt != 1) {
#	$curRes++;
			}
			$curChain++;
			if ($curChain eq "10") {
				$curChain = "A";
			}
		#	$curRes = 1;
		#	$curRes++;
			$iCurRes =1;
		}
	}
}


print REP "END\n";
