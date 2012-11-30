#!/usr/bin/perl
use POSIX;


my @neg;
my @pos;

#Args dir_with_pdbs output;
opendir(DH, $ARGV[0]) || die "couldn't open $ARGV[0]: $!\n";

while ($file = readdir(DH)) {
    if ($file !~ /.*pdb/) {
        next;
    }
	if ($file =~ /.*pdb.+/){
		next;
	}
    $step = $file;
    $step =~ s/\.pdb//;
    print "$step";
	open(FH, "$ARGV[0]/$file") || die  "couldn't open $file,: $!\n";
	@pairs = qw();
    while ($line = readline(FH)) {
        $line =~ s/^\s+//;
        @params = split(/\s+/, $line);
		if($params[2] eq "CG" && ($params[3] eq "ASP" || $params[3] eq "GLU")) {
            $pos = tell(FH);
            while($line = readline(FH)) {
                @params2 = split(/\s+/, $line);
                if (($params2[2] eq "C" || $params[2] eq "CZ") && ($params2[3] eq "ARG" || $params2[3] eq "LYS" || $params2[3] eq "HIS") ) { #&& $params2[4] != ($params[4]+1)) {
                    $dist = ($params[5] - $params2[5])**2;
                    $dist += ($params[6] - $params2[6])**2;
                    $dist += ($params[7] - $params2[7])**2;
                    $dist = sqrt($dist);
                    print "\t$dist";
					$pair = "$params[3]$params[4]-$params2[3]$params2[4]";
					push(@pairs,$pair);
				}
			}
			seek(FH, $pos, 0);
		}
		if(($params[2] eq "C" || $params[2] eq"CZ") && ($params[3] eq "ARG" || $params[3] eq "LYS" ||$params[3] eq "HIS")) {
			$pos = tell(FH);
			while($line = readline(FH)) {
				@params2 = split(/\s+/, $line);
				if ($params2[2] eq "CG" && ($params2[3] eq "ASP" || $params2[3] eq "GLU" ) ){#&& $params2[4] != ($params[4] +1)) {
					$dist = ($params[5] - $params2[5])**2;
					$dist += ($params[6] - $params2[6])**2;
					$dist += ($params[7] - $params2[7])**2;
					$dist = sqrt($dist);
					print "\t$dist";
					$pair = "$params[3]$params[4]-$params2[3]$params2[4]";
					push(@pairs,$pair);
				}
			}
			seek(FH, $pos, 0);
		}
			
	}
	print "\n";
	#print "\n# step @pairs\n";
	#exit;
}
for ($i = 0; $i < @pairs; $i++) {
	print "\@ s$i legend \"$pairs[$i]\"\n";
	print "\@ s$i hidden false\n";
	print "\@ s$i on\n";
	
	
}
for ($i = 0; $i < @pairs; $i++) {
	print "\@ sort s$i X ascending\n";
}
