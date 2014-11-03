#!/usr/bin/perl
#
# Calculate the forward and back acceptance rates.
# From a NAMD history file.
#
# USAGE exhcange_prob.pl job_name. $replicas
#

$jobname = $ARGV[0];
$replicas = $ARGV[1];

print STDERR "Jobname $jobname $replicas\n";

for ($rep = 0; $rep < $replicas; $rep++) {
	$rep_loc = $jobname;
	$rep_loc =~ s/\%s/$rep/;
	open (FH, "$rep_loc.$rep.history") || die "Couldn't open $rep_loc.$rep.history for reading: $!\n";
	$attempts = 0;
	$sucess = 0;
	$previous = $rep;
	while ($line = readline(FH)) {
		@params = split(/\s+/, $line);
		$attempts ++;
		if ($params[1] != $previous) {
			$sucess ++;
			$previous = $params[1];
		}
	}
	close(FH);
	$sucess = $sucess/$attempts;
	print "$rep\t$sucess\n";
}
