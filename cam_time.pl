#!/usr/bin/perl

# Loops over .camshift files and produces an average of them
opendir(CUR, "$ARGV[0]") || die "Couldn't open dir $ARGV[0]\n";
$res = $ARGV[1];
for ($i = 0; $i <= $res; $i++) {
	@ha[$i] = 0;
	@ca[$i] = 0;
	@hn[$i] = 0;
	@n[$i] = 0;
	@c[$i] = 0;
	@cb[$i] = 0;
}
$n  = 0;
open(HAT, ">HA_time.tsv") || die "Couldn't open HA_time for writing\n";
open(CAT, ">CA_time.tsv") || die "Couldn't open CA_time for writing\n ";
open(HNT, ">HN_time.tsv") || die "couldn;t opne HB_time for writing\n";
open(NT, ">N_time.tsv") || die "Couldn't open N_time fopr writing\n";
open(CT, ">C_time.tsv") || die "Couldn't open C_time for writing\n";
open(CBT, ">CB_time.tsv") || die "Couldn't open CB_time for writing\n";
while ($file = readdir(CUR)) {
	if ($file =~ /.*camshift.*/) {
		open(IN, "$ARGV[0]/$file")|| die "couldn't open $ARGV[0]/$file\n";
		$time = $file;
		$time =~ s/.pdb.*//;
		while ($line = readline(IN)) {
			if ($line =~ /.*ID.*/) {
			#	print $line;
				last;
				
			}
		}
		$line = readline(IN);
		while($line = readline(IN)) {
		#	print $line;
			$line =~ s/^\s+//;
			@params = split(/\s+/, $line);
			$ha[$params[0]] = $params[2];
			$ca[$params[0]] = $params[3];
			$hn[$params[0]] = $params[4];
			$n[$params[0]] = $params[5];
			$c[$params[0]] = $params[6];
			$cb[$params[0]] = $params[7];
		}
		close(IN);
		print HAT "$time";
		print HNT "$time";
		print NT "$time";
		print CBT "$time";
		print CT "$time";
		print CAT "$time";
		for ($i = 1; $i <= $res; $i++) {
			print HAT "$ha[$i]\t";
			print CAT "$ca[$i]\t";
			print HNT "$hn[$i]\t";
			print HN  "$n[$i]\t";
			print CT  "$c[$i]\t";
			print CBT "$cb[$i]\n";
		}
		print HAT "\n";
		print HNT "\n";
		print NT "\n";
		print CBT "\n";
		print CT "\n";
		print CAT "\n";

	}
}
close(HAT);
close(HNT);
close(NT);
close(CBT);
close(CT);
close(CAT);
