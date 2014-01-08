#!/usr/bin/perl
my $clust = 0;
my @prev;
my $time = 0;
my $curr = 0;
my $n=0;
my @accepted;
push(@prev, -1);
open (FH, $ARGV[0]) || die "couldn't open $ARGV[0]\n";

open(OUT, ">clust_accepted_time.xvg");


print OUT "@\ttitle \"Clusters\"\n";
print OUT "@\txaxis\tlabel	\"Time(ps)\"\n";
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
	$prev[$curr] ++;
	if($prev[$curr] > 5 && !existing($curr)) {
		push(@accepted, $curr);
		$n++;
	}	
	print OUT "\t$time\t$n\n";
	push (@times, $time);
}

sub existing {
	local $find = shift;
	local $found = 0;
#	print "$find in @prev\n";
	foreach $test (@accepted) {
	#	print "$test\n";
		if ($find == $test) {
#			print $test;
			$found = 1;
		}
	}
	return($found);
}

