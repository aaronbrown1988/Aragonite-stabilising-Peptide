#!/usr/bin/perl
#
#
# USAGE: ghbond-map.pl LOG XPM

open(LOG, "$ARGV[0]") || die " Couldn't open $ARGV[0]: $!\n";
open(XPM, "$ARGV[1]") || die " Couldn't open $ARGV[1]: $!\n";

while ($line = readline(LOG)) {
	if ($line =~ /^[#@!].*/) {
		next;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	
	# Deterine which is the chitin and which is the peptide.
	#
	if ($params[0] =~ /.*CHT.*/) {
		$cht = $params[0];
		$pep = $params[2];
	} else {
		$cht = $params[2];
		$pep = $params[0];
	}
	
	# Zero CHT histogram;
	$cht =~ s/CHT[0-9]+//;
	$cht_hist{$cht} = "";
	#build LUT
	push (@cht_lut, $cht);

	$pep =~ m/([A-Z]{3}[0-9]+)/;
	$res = $1;
	$at = $pep;
	$at =~ s/[A-Z]{3}[0-9]+//;
	if ($at !~ /\b(O|N|F|C)\b/) {
		push(@sc, "1");
	} else {
		push(@sc, "0");
	}
#	print "# Res $res at $at\n";
	$res_hist{$res} = "";
	$sc_hist{$res} = "";
	push(@res_lut, $res);
}

close(LOG);
#print "# ", scalar(keys(%res_hist)), " peptide residues found\n";

while ($line = readline(XPM)) {
	if ($line =~ /^\/\*.*/) {
		next;
	}
	if ($frames eq undef) {
			
		$line = readline(XPM);
		$line =~ s/\"//g;
		$line =~ s/\s+.+//;
		$frames = $line;
#		print "# Frames: $frames\n";
		#skip next two lines
		$line = readline(XPM);
		$line = readline(XPM);
		$ln = 0;
		next;
	}
	$line =~ s/\"//g;
	for ($i = 0; $i < $frames; $i++) {
		$x = "N";
		$x = substr($line, $i, 1);
		if ($x eq "o") {

			$res = $res_lut[$ln];
			$res_hist{$res}++;
			if ($sc[$ln] == 1) {
				$sc_hist{$res}++;
			}
		}
	}
	$ln++;
}

foreach $res (keys(%res_hist)) {
	print "$res ", ($res_hist{$res}*100)/$frames, "\t", ($sc_hist{$res}*100)/$frames, "\n";
}

