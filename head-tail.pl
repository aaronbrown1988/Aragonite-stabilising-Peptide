#!/usr/bin/perl
# Quick and dirty Script to Head-Tail link chitin chains
#Linked through CHT1:01->CHT2:C4


open(FH, "$ARGV[0]") || die " $!";
open(OUT,">$ARGV[0].new");


while ($line = readline(FH)) {
	print OUT $line;
	if ($line=~/.*atoms.*/) {
		last;
	}
}

my $mC1=0;
my $mO1=0;
my $mO5 = 0;
my $nC1=0;
my $nC2=0;
my $nC4=0;
my $nC3=0;
my $nO5=0;
my $nC6=0;
my $nH3=0;
my $nO3=0;
my $nC5=0;

my $n=9e9;
my $m=0;

while ($line =readline(FH)) {
	print OUT $line;
	$line =~ s/^\s+//;
	if (length($line) < 3) {
		last;

	}
	if($line =~ /^;.*/) {
		next;
	}
	
	@params = split(/\s+/, $line);
	if ($params[2] <= $n) {
		$n = $params[2];
		if ($params[4] =~ /.*C4.*/) {
			$nC4 = $params[0];
		} elsif($params[4] =~/.*C3.*/) {
			$nC3 = $params[0];
		
		} elsif($params[4] =~/.*C2.*/) {
			$nC2 = $params[0];
		
		} elsif($params[4] =~/.*C1.*/) {
			$nC1 = $params[0];
		} elsif($params[4] =~/.*C5.*/) {
			$nC5 = $params[0];
		} elsif($params[4] =~/.*C6.*/) {
			$nC6 = $params[0];
		} elsif($params[4] =~/.*O5.*/) {
			$nO5 = $params[0];
		} elsif($params[4] =~/.*H3.*/) {
			$nH3 = $params[0];
		} elsif($params[4] =~/.*H4.*/) {
			$nH4 = $params[0];
		} elsif($params[4] =~/.*H5.*/) {
			$nH5 = $params[0];
		} elsif($params[4] =~/\bO3\b/) {
			$nO3 = $params[0];
		} elsif($params[4] =~/.*O5.*/) {
			$nO5 = $params[0];
		}
	} 
	if($params[2] >= $m) {
		$m = $params[2];
		if ($params[4] =~/.*C1.*/) {
			$mC1 = $params[0];
		} elsif( $params[4] =~ /.*O1.*/) {
			$mO1 = $params[0];
		} elsif( $params[4] =~ /.*H1.*/) {
			$mH1 = $params[0];
		
		} elsif( $params[4] =~ /.*O5.*/) {
			$mO5 = $params[0];
		} elsif( $params[4] =~ /.*C2.*/) {
			$mC2 = $params[0];
		}
	}
}

print "$ARGV[0]: Linking $m back to $n via $mC1-> $mO1 ->$nC4\n";

#Move to bonds
while ($line = readline(FH)) {
	print OUT $line;
	if ($line =~ /.*bonds.*/) {
		last;
	}
}
print OUT "$mO1\t$nC4\t1\n";

#pairs
while ($line = readline(FH)) {
	print OUT $line;
	if($line =~ /.*pairs.*/) {
		last;
	}
}
print OUT "$mO1\t$nH5\t1\n";
print OUT "$mO1\t$nO5\t1\n";
print OUT "$mO1\t$nC2\t1\n";
print OUT "$mO1\t$nH3\t1\n";
print OUT "$mO1\t$nO3\t1\n";
print OUT "$mO1\t$nC6\t1\n";
print OUT "$mO5\t$nC4\t1\n";
print OUT "$mC2\t$nC4\t1\n";
print OUT "$mH1\t$nC4\t1\n";
print OUT "$mC1\t$nC4\t1\n";
print OUT "$mC1\t$nC3\t1\n";
print OUT "$mC1\t$nC5\t1\n";


#Go to angles
while ($line = readline(FH)) {
	print OUT $line;
	if($line =~ /.*angles.*/) {
		last;
	}
}
print OUT "$mC1\t$mO1\t$nC4\t5\n";
print OUT "$nH4\t$nC4\t$mO1\t5\n";
print OUT "$mO1\t$nC4\t$nC5\t5\n";
print OUT "$mO1\t$nC4\t$nC3\t5\n";

#Move to dih
while ($line = readline(FH)) {
	print OUT $line;
	if ($line =~/.*dihedrals.*/) {
		last;
	}
}
print ";link dihedrals\n";
print OUT "$mO5\t$mC1\t$mO1\t$nC4\t9\n";
print OUT "$mH1\t$mC1\t$mO1\t$nC4\t9\n";
print OUT "$mC2\t$mC1\t$mO1\t$nC4\t9\n";

print OUT "$mC1\t$mO1\t$nC4\t$nC3\t9\n";
print OUT "$mC1\t$mO1\t$nC4\t$nC5\t9\n";
print OUT "$mC1\t$mO1\t$nC4\t$nH4\t9\n";


print OUT "$nH5\t$nC5\t$nC4\t$mO1\t9\n";
print OUT "$nO5\t$nC5\t$nC4\t$mO1\t9\n";
print OUT "$nC6\t$nC5\t$nC4\t$mO1\t9\n";

print OUT "$nC2\t$nC3\t$nC4\t$mO1\t9\n";
print OUT "$nH3\t$nC3\t$nC4\t$mO1\t9\n";
print OUT "$nO3\t$nC3\t$nC4\t$mO1\t9\n";
print ";end link dihedrals\n";

while($line = readline(FH)) {
	print OUT $line;
}
close(OUT);
close(FH);
