#!/usr/bin/perl
#
# This program genetates secondary structure plots from
# Ramachandran Data.
# USAGE ss_rama.pl rama.xvg dt 

open(FH, "$ARGV[0]") || die ("Couldn't open $ARGV[0]: $!\n");
open(SS, ">ss_rama.xvg") || die "Couldn't open ss_rama.xvg for writiing: $!\n";

if ($ARGV[1] eq undef) {
	die "Need to know the timestep";
}

$t = 0;
while ($line = readline(FH)) {
	if ($line =~ /^[@#].*/) {
		next;
	}
	@params = split(/\s+/, $line);
	$res = $params[2];
	$res =~ s/.+\-//;
	$class = classify(@params);
	print SS "$t";
	for ($i = 0; $i < 8; $i++) {
		if ($i == $class ) {
			print SS "\t$res";
		} else {
			print SS "\t-1";
		}
	}
	print SS "\n";
	$t += $ARGV[1];
}

print SS <<EOF;

@ world xmin 0
@ world ymin 0
@ title "Secondary structure with time"
@ xaxis label "Time"
@ yaxis label "Residue"
@ s0 SYMBOL 8
@ s1 SYMBOL 8
@ s2 SYMBOL 8
@ s3 SYMBOL 8
@ s4 SYMBOL 8
@ s5 SYMBOL 8
@ s6 SYMBOL 8
@ s7 SYMBOL 8
@ s0 SYMBOL SIZE 0.5
@ s1 SYMBOL SIZE 0.5
@ s2 SYMBOL SIZE 0.5
@ s3 SYMBOL SIZE 0.5
@ s4 SYMBOL SIZE 0.5
@ s5 SYMBOL SIZE 0.5
@ s6 SYMBOL SIZE 0.5
@ s7 SYMBOL SIZE 0.5
@ s0 SYMBOL FILL 1
@ s1 SYMBOL FILL 1
@ s2 SYMBOL FILL 1
@ s3 SYMBOL FILL 1
@ s4 SYMBOL FILL 1
@ s5 SYMBOL FILL 1
@ s6 SYMBOL FILL 1
@ s7 SYMBOL FILL 1


@ s0 LINESTYLE 0
@ s1 LINESTYLE 0
@ s2 LINESTYLE 0
@ s3 LINESTYLE 0
@ s4 LINESTYLE 0
@ s5 LINESTYLE 0
@ s6 LINESTYLE 0
@ s7 LINESTYLE 0

@ s0 legend "Alpha In"
@ s1 legend "Alpha Out"
@ s2 legend "Alpha Left"
@ s3 legend "Gamma"
@ s4 legend "Gamma L"
@ s5 legend "Beta"
@ s6 legend "PPII"
@ s7 legend "Other"

EOF
sub classify {
	local ($x,$y) = @_;
	if (in_alpha_i($x,$y)) {
		$classify = 0;
	} elsif (in_alpha_o ($x,$y)) {
		$classify = 1;
	} elsif (in_alpha_l($x,$y)) {
		$classify = 2;
	} elsif(in_gamma($x,$y)) {
		$classify = 3;
	}elsif (in_gamma_l($x,$y)) {
		$classify = 4;
	} elsif(in_beta($x,$y)) {
		$classify = 5;
	}elsif(in_pp2($x,$y)) {
		$classify = 6;
	} else {
		$classify = 7;
	}
	return $classify;
}


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
