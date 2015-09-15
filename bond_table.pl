#!/usr/bin/perl\
#
# Process Bond_data.dat to get unique matched table
#
my @pairs;
my %table;
my %bb;
my %scb;
my %scsc;
my %uniq;
open(FH, "Bond_data.dat") || die "Couldn't open Bond_data.dat: $!\n";
$files = 0;
while($line = readline(FH)) {
	chomp($line);
 	@params = split(/,/,$line);
	undef @frame;	
	for ($i=1; $i < scalar(@params); $i ++) {
		@res = split(/-/, $params[$i]);
		@at = @res;
		$at[0] =~ s/[A-Z0-9]+\://;
		$at[1] =~ s/[A-Z0-9]+\://;
		$res[0] =~ s/\:[A-Z0-9]+//;
		$res[1] =~ s/\:[A-Z0-9]+//;
		$found = 0;
#	print "@res\n";
		foreach $test (@pairs) {
			if ($test eq "$res[0]-$res[1]") {
				$found = 1;
				$pair = "$res[0]-$res[1]";
			} elsif ($test eq "$res[1]-$res[0]") {
				$found = 1;
				$pair = "$res[1]-$res[0]";
			}
		}
		if ($found == 0) {
			$pair = "$res[0]-$res[1]";
			$table{$pair} = 0;
			$bb{$pair} = 0;
			$scb{$pair} = 0;
			$scsc{$pair} = 0;
			push(@pairs,"$res[0]-$res[1]");
		}
		$found = 0;
		foreach $test (@frame) {
			if  ($test eq $pair) {
				$found = 1;
			}
		}
		if ($found == 0 ) {
			$uniq{$pair}++;
			push(@frame,$pair);
		}

		$table{$pair}++;
		if ($at[0] =~ /(CA|N|C|O|NT)\b/) {
			if($at[1] =~ /(CA|N|C|O|NT)\b/) {
				$bb{$pair} ++;
			} else {
				$scb{$pair} ++;
			}
		} else {
			if($at[1] =~ /(CA|N|C|O|NT)\b/) {
				$scb{$pair} ++;
			} else {
				$scsc{$pair} ++;
			}
		}
	}
	$files ++;	
}

foreach $key (keys(%table)) {
	$uniq{$key}  /= $files*0.01;
	$bb{$key} /= $table{$key}*(1/$uniq{$key});
	$scb{$key} /= $table{$key}*(1.0/$uniq{$key});
	$scsc{$key} /= $table{$key}*(1.0/$uniq{$key});
	print "$key\t$uniq{$key}\t$bb{$key}\t$scb{$key}\t$scsc{$key}\n";
}

