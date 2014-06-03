#!/usr/bin/perl
#
# Quick script to generate the history file required for sort replicas
#

if (scalar(@ARGV) != 3 ) {
	die "got $argc arguments. USAGE tiger-replica-history.pl LOGFILE BASENAME Steps\n";
}

$basename = $ARGV[1];
$dt= $ARGV[2];


open (LOG, "$ARGV[0]") || die " couldn't open $ARGV[0]: $!\n";

# Get initial Temepratures of the replicas

while ($line = readline(LOG)) {
	if ($line =~ /.*TEMPERATURE.*/) {
		last;
	}
}
$i = 0;
@params = split(/\s+/, $line);
$lut{$params[2]} = $i;
$i++;
push(@prev, $params[2]);
while ($line = readline(LOG)) {
	if ($line !~ /.*TEMPERATURE.*/) {
		last;
	}
	@params = split(/\s+/, $line);
	push(@prev, $params[2]);
	$lut{$params[2]} = $i;
	$i++;
}

$nreplicas = scalar(@prev);

#Open all the history files;
for ($i = 0; $i < $nreplicas; $i++ ) {
	local *FILE;
	open (FILE, ">$basename.$i.history") || die "Couldn't open $basename/$i.history for writing:$!\n";
	push (@hist,*FILE);
}
$time = 0;
while ($line = readline(LOG)) {
	if ($line =~ /^RIDRAND.*/) {
		@now = @prev;
		$time += $dt;
		while ($line = readline (LOG)) {
			if ($line =~ /^EXCHANGE.*/ ) {
				$line =~ s/[()]//g;
				@params = split(/\s+/,$line);
				$now[$params[4]] = $params[3];
				$now[$params[2]] = $params[5];
			} elsif ($line =~ /^REASSIGN.*/) {
				$line =~ s/[()]//g;
				@params = split(/\s+/,$line);
				$now[$params[1]] = $params[4];
			} else {
				last;
			}
		}
		for ($i = 0; $i < $nreplicas; $i++ ){
			$file = $hist[$i];
			print $file "$time $lut{$now[$i]} $prev[$i] $now[$i]\n";
			$prev[$i] = $now[$i];
		}
	}
}

for($i=0; $i < $nreplicas; $i++) {
	close($hist[$i]);
}
