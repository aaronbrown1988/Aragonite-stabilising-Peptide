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

while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
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
}

print "$alpha_i\t$alpha_o\t$alpha_l\t$beta\t$gamma\t$gamm_l\t$pp2\t$other\n";


sub in_alpha_i {
	local ($x,$y) = @_;
	$ret = 0;
	if ($x > -90 && $x < -30 && $y <-30 && $y > -70) {$ret = 1;}
	return $ret;
}

sub in_alpha_l {
	local ($x,$y) = @_;
	$ret = 0;
	if( $x> 30 && $x < 100 && $y < 70 && $y> 20) { $ret = 1;}
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
	if ($x < -110 && $y > 90) { $ret = 1;}
	if ($x < -110 && $y < -150) { $ret = 1;}
	if ($x > 170 && $y > 90) { $ret = 1;}
	return $ret;
}


sub in_pp2 {
	local ($x,$y) = @_;
	$ret = 0;
	if ($x < 0 && $x >-110 && $y > 90) { $ret = 1;}
	if ($x< 0 && $x > -110 && $y <-150) {$ret = 1;}
	return $ret;
} 
	