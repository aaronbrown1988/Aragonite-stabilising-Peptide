#!/usr/bin/perl
my $clust = 0;
my @prev;
my $time = 0;
my $curr = 0;
push(@prev, -1);
open (FH, $ARGV[0]) || die "couldn't open $ARGV[0]\n";

open(OUT, ">clust_time.xvg");


print OUT "@\ttitle \"Clusters\"\n";
print OUT "@\txaxis\tlabel	\"Steps\"\n";
print OUT "@\tyaxis\tlabel	\"# Clusters\"\n";
print OUT "\@TYPE xy\n";
print OUT "@    s0 symbol 2\n";
print OUT "@    s0 symbol size 0.2\n";
print OUT "@    s0 linestyle 0\n";


while ($line = readline(FH)) {
	if ($line =~ /^[#@].*/) {
		next;
	}
	($throw, $time, $curr) = split(/\s+/, $line);
	$time *= 1000;
	if (!existing($curr)) {
		$clust ++;
		push (@times, $time);
		push(@prev, $curr);
	}
	print OUT "\t$time\t$clust\n";
}

print OUT "\t$time\t$clust\n";
sub existing {
	local $find = shift;
	local $found = 0;
#	print "$find in @prev\n";
	foreach $test (@prev) {
	#	print "$test\n";
		if ($find == $test) {
#			print $test;
			$found = 1;
		}
	}
	return($found);
}

