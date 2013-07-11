#!/usr/bin/perl
#
# Usage : cd_average.pl CD_Spectra_DIR

opendir(DH, "$ARGV[0]") || die "Couldn't open directory\n";

while($file = readdir(DH)) {
	if ($file =~ /.ps/) {
		next;
	}
	if ($file =~ /\bcd\b/) {
		$file =~ s/.cd.*//;
		push (@files,$file);
	}
}

closedir(DH);
@files = sort {$a <=> $b } @files;
for ($i = 0; $i < scalar(@files); $i++) {
	open(FH, "$ARGV[0]/$files[$i].cd") || die "couldn't open $ARGV[0]/$files[$i].cd:$!\n ";
	$n = 0;
	while ($line = readline(FH)) {
		$line =~ s/^\s+//;
		@params = split(/\s+/, $line);
		$deg[$n] = $params[0];
		$vals[$n] += $params[1];
		$n ++;
	}
}
for ($i = 0; $i < scalar(@deg); $i++) {
	$vals[$i] = $vals[$i] / scalar(@files);
	print "$deg[$i]\t$vals[$i]\n";
}


