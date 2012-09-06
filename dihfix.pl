#!/usr/bin/perl

#usage snap.top ff_folder
open(TOP, "$ARGV[0]") || die "Couldn't open topology $ARGV[0]\n";
open(FF, "$ARGV[1]/ffbonded.itp") || die "couldn't open bonded interactions: $ARGV[1]/ffbonded.itp\n";
open(OUT, ">$ARGV[0].new") || die "Couldn't open new $ARGV[0].new for writing\n"; 

$l = $ARGV[2]/$ARGV[3];

while ($line = readline(TOP)) {
	if ($line =~ /.*atoms.*/) {
		last;
	}
}

while($line = readline(TOP)) {
	if ($line =~ /^;.*/) {
		next;
	}
	if (length($line) < 3 || ($line =~ /^\[.*/)) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$atlut[$params[0]] = $params[1];
}
# Proper dihedrals #
while ($line = readline(FF)) {
	if ($line =~ /.*dihedraltypes.*/) {
		last;
	}
}
$n=0;
while ($line = readline(FF)) {
	if ($line =~ /^;.*/) {
		next;
	}
	if (length($line) < 3) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$phi[$n] = $params[5];
	$k[$n] = $params[6];
	$multi[$n] = $params[7];
	$name = "$params[0]-$params[1]-$params[2]-$params[3]";
	$dihlut{$name} = "$dihlut{$name} $n";
	$n++;
}

foreach $test (keys(%dihlut)) {
	if ($test =~ /.*X.*/) {
		next;
	}
	$wild = $test;
	$wild =~ s/-.*-.*-/-X-X-/;
	if (length($dihlut{$wild}) > 0) {
		$dihlut{$test} = "$dihlut{$test} $dihlut{$wild}";
	}
	$wild = $test;
	$wild =~ s/^[A-Z0-9]*-/X-/;
	$wild =~ s/-[A-z0-9]+(?!.+)/-X/;
	print "WILD $wild\n";
	if (length($dihlut{$wild}) > 0) {
		$dihlut{$test} = "$dihlut{$test} $dihlut{$wild}";
	}
}
# Impropers 
while ($line = readline(FF)) {
	if ($line =~ /.*dihedraltypes.*/) {
		last;
	}
}
$n=0;
while ($line = readline(FF)) {
	if ($line =~ /^;.*/) {
		next;
	}
	if (length($line) < 3) {
		last;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$iphi[$n] = $params[5];
	$ik[$n] = $params[6];
	$name = "$params[0]-$params[1]-$params[2]-$params[3]";
	$implut{$name} = "$implut{$name} $n";
	$n++;
}

foreach $test (keys(%implut)) {
	if ($test =~ /.*X.*/) {
		next;
	}
	$wild = $test;
	$wild =~ s/-.*-.*-/-X-X-/;
	if (length($implut{$wild}) > 0) {
		$implut{$test} = "$implut{$test} $implut{$wild}";
	}
	$wild = $test;
	$wild =~ s/^[A-Z0-9]*-/X-/;
	$wild =~ s/-[A-z0-9]+(?!.+)/-X/;
	print "WILD $wild\n";
	if (length($implut{$wild}) > 0) {
		$implut{$test} = "$implut{$test} $implut{$wild}";
	}
}


seek(TOP, 0, 0);


#Proper Dihedrals
while($line = readline(TOP)) {
	print OUT "$line";
	if ($line =~ /.*dihedral.*/) {
		last;
	}
}

while ($line = readline(TOP)) {
	if (length($line) < 3) {
		last;
	}
	if ($line =~ /^;.*/) {
		next;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$name = "$atlut[$params[0]]-$atlut[$params[1]]-$atlut[$params[2]]-$atlut[$params[3]]";
	@dihs = split(/ /, $dihlut{$name});
	if (@dihs == 0) {
		$name = "$atlut[$params[0]]-X-X-$atlut[$params[3]]";
		@dihs = split(/ /, $dihlut{$name});
	}
	if (@dihs == 0) {
		$name = "X-$atlut[$params[1]]-$atlut[$params[2]]-X";
		@dihs = split(/ /, $dihlut{$name});
	}
	if (@dihs == 0) {
		$name = "$atlut[$params[3]]-X-X-$atlut[$params[0]]";
		@dihs = split(/ /, $dihlut{$name});
	}
	if (@dihs == 0) {
		$name = "X-$atlut[$params[2]]-$atlut[$params[1]]-X";
		@dihs = split(/ /, $dihlut{$name});
	}
	if (@dihs == 0) {
		print "$atlut[$params[0]]-$atlut[$params[1]]-$atlut[$params[2]]-$atlut[$params[3]] couldn't be matched\n";
		exit;
	}
	#print "$name\n";
	foreach (@dihs) {
		$phib =  $phi[$_];
		$kb = $l * $k[$_];
		print OUT "$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\t$phi[$_]\t$k[$_]\t$multi[$_]\t$phib\t$kb\t$multi[$_]\n";
	}
}
while($line = readline(TOP)) {
	print OUT "$line";
	if ($line =~ /.*dihedral.*/) {
		last;
	}
}

while ($line = readline(TOP)) {
	if (length($line) < 3) {
		last;
	}
	if ($line =~ /^;.*/) {
		next;
	}
	$line =~ s/^\s+//;
	@params = split(/\s+/, $line);
	$name = "$atlut[$params[0]]-$atlut[$params[1]]-$atlut[$params[2]]-$atlut[$params[3]]";
	@dihs = split(/ /, $implut{$name});
	if (@dihs == 0) {
		$name = "$atlut[$params[0]]-X-X-$atlut[$params[3]]";
		@dihs = split(/ /, $implut{$name});
	}
	if (@dihs == 0) {
		$name = "X-$atlut[$params[1]]-$atlut[$params[2]]-X";
		@dihs = split(/ /, $implut{$name});
	}
	foreach (@dihs) {
		$phib =  $iphi[$_];
		$kb = $l * $ik[$_];
		print OUT "$params[0]\t$params[1]\t$params[2]\t$params[3]\t$params[4]\t$iphi[$_]\t$ik[$_]\t$phib\t$kb\n";
	}
}




while ($line = readline(TOP)) {
	print OUT $line;
}

