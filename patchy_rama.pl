#!/usr/bin/perl

#
# Patchy Ramachandran plot 
#
#

open (FH, $ARGV[0]) || die "Couldn't open: $ARGV[0]\n";
$alpha_o=0;
$alpha_l=0;
$alpha_i = 0;
$gamma=0;
$gamm_l = 0;
$beta = 0;
$pp2 = 0;

$other = 0;

$ARGV[0] =~ s/.*-//;
$ARGV[0] =~ s/\.xvg//;
$n =0;
while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
	$line =~ s/^\s+//; 
	($x, $y, $type) = split(/\s+/, $line);
	if (in_alpha_i($x,$y)) {
		$alpha_i++;
	} elsif (in_alpha_o ($x,$y)) {
		$alpha_o++;
	} elsif (in_alpha_l($x,$y)) {
		$alpha_l++;
	} elsif(in_gamma($x,$y)) {
		$gamma++;
	}elsif (in_gamma_l($x,$y)) {
		$gamm_l++;
	} elsif(in_beta($x,$y)) {
		$beta++;
	}elsif(in_pp2($x,$y)) {
		$pp2++;
	} else {
		$other ++;
	} 
	$n++;
}

$alpha_i /= $n;
$alpha_o /= $n;
$alpha_l /= $n;
$beta /= $n;
$gamma /=$n;
$gamm_l /= $n;
$pp2 /= $n;
$other /= $n;

print "$ARGV[0]\t$alpha_i\t$alpha_o\t$alpha_l\t$beta\t$gamma\t$gamm_l\t$pp2\t$other\n";


sub in_alpha_i {
	local ($x,$y) = @_;
	$ret = 0;
	if ($x > -90 && $x < -30 && $y <-15 && $y > -75) {$ret = 1;}
	return $ret;
}

sub in_alpha_l {
	local ($x,$y) = @_;
	$ret = 0;
	if( $x> 30 && $x < 90 && $y < 50 && $y> 15) { $ret = 1;}
	return $ret;
}

sub in_alpha_o {
	local ($x,$y) = @_;
	$ret = 1;
	if ($x  > 0) { $ret = 0; }
	if ($y > 30 || $y < -90) { $ret = 0; }
	return $ret;
}

sub in_gamma {
	local ($x,$y) = @_;
	$ret = 0;
	if ($x < 0 && $y > 30 && $y < 90) { $ret = 1;}
	return $ret;
}

sub in_gamma_l {
	local ($x,$y) = @_;
	$ret = 0;
	if( $x > 60 && $x < 120 && $y>-120 && $y < 0) { $ret = 1;}
	return $ret;
}

sub in_beta {
	local ($x,$y)=@_;
	$ret =0;
	if ($x < -100 && $y > 90) { $ret = 1;}
	if ($x < -100 && $y < -150) { $ret = 1;}
	if ($x > 150 && $y > 90) { $ret = 1;}
	return $ret;
}


sub in_pp2 {
	local ($x,$y) = @_;
	$ret = 0;
	if ($x < 0 && $x >-100 && $y > 90) { $ret = 1;}
	if ($x< 0 && $x > -100 && $y <-150) {$ret = 1;}
	return $ret;
} 
	
