#!/usr/bin/perl

#
# Scales masses of side chains in a CHARMM PSF file
# leaves anything that is a C,N,O,or CA unharmed.
# Arguments: PSF_File solute_scaling_factor water_scaling

open(OLD, "$ARGV[0]") || die "Couldn't open $ARGV[1]\n";
open(NEW, ">$ARGV[0].new") || die "Couln't open new file for writing\n";

while ($line = readline(OLD)) {
	print NEW $line;
	if ($line =~ /.*NATOM.*/) {
		last;
}}
while ($line = readline(OLD)) {
	$line =~ s/^\s+//;
	if (length($line) < 3) {
		last;
	}

	@params = split(/\s+/, $line);
	if ($params[4] eq 'HW' || $params[4] eq 'OW') {
		$params[7] *= $ARGV[2];
	} elsif ($params[4] ne 'CA' && $params[4] ne 'C'&&$params[4] ne 'O'&&$params[4] ne 'N') {
		print "\'$params[4]\'\n";
		$params[7] *= $ARGV[1];
	} 
		print NEW "\t$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4] \t$params[5]\t$params[6]\t$params[7]\t$params[8]\n";
	
}

print NEW "\n";

while ($line = readline(OLD)) {
	print NEW $line;
}
	
