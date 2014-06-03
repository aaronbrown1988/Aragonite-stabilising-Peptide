#!/usr/bin/perl

my @exchanges;
my @accept;

open(LOG, "$ARGV[0]" ) || die "Couldn't open $ARGV[0]: $! \n";

while ($line = readline(LOG)) {
	if ($line =~ /^RIDRAND.*/) {
		@params = split(/\s+/, $line);
		$exchanges[$params[1]]++;
	} elsif ($line =~ /^EXCHANGE_ACCEPT.*/) {
		@params = split(/\s+/, $line);
		$accept[$params[3]]++;
	}
}

for($i=0; $i < @exchanges; $i++) {
	$x = $accept[$i]/$exchanges[$i];
	print "$i\t$x\n";
}



	

