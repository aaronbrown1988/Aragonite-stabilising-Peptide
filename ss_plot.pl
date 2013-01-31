#!/usr/bin/perl

#
# This program produces the awesome secondary structure plots
# It's basically a warpper around stride
# Usage ss_plot pdb_folder > ss.xvg

#Stride Type hash DO NOT EDIT
%stride = (
	'H' => 0,
	'G' => 1,
	'I' => 2,
	'E' => 3,
	'B' => 4,
	'b' => 4,
	'T' => 5,
	'C' => 6 );

@names = ("Alpha Helix", "3-10 Helix", "Pi - helix", "Extended Conformation", "Beta", "Turn", "RC" );










#print "$ARGV[0]\n";
opendir (DH, "$ARGV[0]") || die "Couldn't open directory $ARGV[0]";
while ($line = readdir(DH)) {
	if ($line =~ /.*\.pdb/ && $line !~ /.*camshift/ ) {
		push (@pdbs, $line);
	}
}
close(DH);
@pdbs = sort { $a <=> $b } @pdbs;


print <<ENDH;

@ XAXIS label "Time (ps)";
@ YAXIS label "Residue Number";


@ s0 SYMBOL 8
@ s1 SYMBOL 8
@ s2 SYMBOL 8
@ s3 SYMBOL 8
@ s4 SYMBOL 8
@ s5 SYMBOL 8
@ s6 SYMBOL 8
@ s0 SYMBOL SIZE 0.5
@ s1 SYMBOL SIZE 0.5
@ s2 SYMBOL SIZE 0.5
@ s3 SYMBOL SIZE 0.5
@ s4 SYMBOL SIZE 0.5
@ s5 SYMBOL SIZE 0.5
@ s6 SYMBOL SIZE 0.5

@ s0 SYMBOL FILL 1
@ s1 SYMBOL FILL 1
@ s2 SYMBOL FILL 1
@ s3 SYMBOL FILL 1
@ s4 SYMBOL FILL 1
@ s5 SYMBOL FILL 1
@ s6 SYMBOL FILL 1


@ s0 LINESTYLE 0
@ s1 LINESTYLE 0
@ s2 LINESTYLE 0
@ s3 LINESTYLE 0
@ s4 LINESTYLE 0
@ s5 LINESTYLE 0
@ s6 LINESTYLE 0
 

ENDH
for ($i = 0; $i < 7; $i++ ) {
	print "\@ s$i legend \"$names[$i]\" \n";
}

foreach $file (@pdbs) {
	$time = $file;
	$time =~ s/\..*//;
	$time *= 10;
	open(SH, "stride $ARGV[0]/$file |" ) || die " stride failed : $!";
	while ($line = readline(SH)) {
		if ($line =~ /^ASG.*/) {
			@params = split (/\s+/, $line);
			print "$time";
			$type = $params[5];
			$type = $stride{$type};
			for ($i = 0; $i < 7; $i++) {
				if ($i eq $type ) {
					print "\t$params[4]";
				} else {
					print "\t-10";
				}
			}
			print "\n";
		}
	}
}

print "\@ WORLD YMIN 1\n";
