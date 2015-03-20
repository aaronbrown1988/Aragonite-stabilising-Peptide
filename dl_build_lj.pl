#!/usr/bin/perl
#
# This script aims to build the LJ interactions for a
# FIELD.frag generated by gmx2dl.pl
# 
# USAGE dl_build_lj.pl ffnonbond.itp
#
# OUTPUT: FIELD.frag with appended LJ terms.
#
# CAVEATs: Will find all molecules in FIELD.FRAG; Doesn;t care too much about format of the FFNONBONDED, as long as it's vaugely right. Also builds cross terms between Molecules.

my $natoms;

open(IN, "FIELD.frag") || die " Couldn't open exisiting FIELD.frag: $!";

while ($line = readline(IN)) {
	chomp($line);
	#Find atoms definition
	if ($line =~ /.*ATOMS.*/) {
		(undef,$natoms) = split(/\s+/,$line);
		#read in atom names
		for ($i = 0; $i < $natoms;$i++) {
			$line = readline(IN);
			chomp($line);
			$line =~ s/\s+//;
			$line =~ s/\s.*//;
			#squirrel them away for later
			push(@atnames, $line);
		}
	}
}
close(IN);

#
# Consolidate atom types down
#
for ($i= 0; $i < scalar(@atnames); $i++) {
	$found = 0;
	for ($j =0; $j < scalar(@attypes); $j++) {
		if ($attypes[$j] eq $atnames[$i]) {
			$found = 1;
		}
	}
	if ($found == 0) {
		push(@attypes, $atnames[$i]);
	}
}

print "Found ",scalar(@atnames)," names, with ", scalar(@attypes)," unique types.\n";

print "Types found: @attypes\n";

#Build Hash with sigma and epsilons in.
open(NB, "$ARGV[0]") || die "Couldn't open $ARGV[0]:$!";

while ($line = readline(NB)) {
	#skip comments;
	if ($line =~ /^[#;\[].*/) {
		next;
	}
	chomp($line);
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$lj{$params[0]} = "$params[5]\t$params[6]";

}

for ($i = 0; $i < scalar(@attypes); $i++ ) {
	for ($j = $i; $j < scalar(@attypes); $j ++) {
		$a = $attypes[$i];
		$b = $attypes[$j];
		if ($lj{$a} eq undef || $lj{$b} eq undef) {
			die "$a or $b not found in itp\n";
		}
		($isig,$ieps) = split(/\s+/,$lj{$a});
		($jsig,$jeps) = split(/\s+/,$lj{$b});
		$sig = 0.5 *($isig +$jsig);
		$eps = ($ieps *$jeps)**0.5;
		print "$attypes[$i]\t$attypes[$j]\t$sig\t$eps\n";
	}
}


