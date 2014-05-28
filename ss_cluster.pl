#!/usr/bin/perl
#
# Groups frames based on dssp data
#

$start_res=0;

if($ARGV != undef) { 
	$start_res = $ARGV[1];
}


open(FH, "$ARGV[0]") || die " Couldn't open $ARGV[0]: $!\n";

while ($line = readline(FH)) {
	if ($line =~ /^static.*/) {
		last;
	}
}
$line = readline(FH);
$line =~ s/\"//g;
@params = split (/\s+/,$line);
$letters = $params[3];
$size = $params[0];
$colors = $params[2];
$residues = $params[1];

$end_res = ($ARGV[2] != undef)? $ARGV[2]:$params[1];


for ($i = 0; $i < $colors; $i++) {
	$line =readline(FH);
	$line =~ s/\"//g;
	@params = split (/\s+/,$line);
	$colors{$params[0]} = $params[4];
}

while ($line = readline(FH)) {
	if ($line !~ /^\/\*.*/) {
		last;
	}
}
$line =~ s/\"//g;
push(@matrix,$line);
for ($i = 1; $i < $residues; $i++) {
	if (eof(FH)) {
		print " WHOA! We onlg got to $i before we got to eof\n";
		die;
	}
	$line = readline(FH);
	$line =~ s/\"//g;
	push(@matrix,$line);
}


for ($i=0; $i < $size; $i++) {
	$ss = "";
	for ($j = $start_res; $j < $end_res; $j++) {
		$x=substr($matrix[$residues-$j-1], $letters*$i, $letters);
		$ss = "$ss$x";
	}
	$clust{$ss}++;
	#print "$ss : $clust{$ss}\n";
	$clust_frames{$ss} = "$clust_frames{$ss} $i";
}

@order = sort{$clust{$b} <=> $clust{$a}} keys(%clust);
print "Cluster[0] has $clust{$order[0]}\n";# members $clust_frames{$order[0]}\n";

open(HIST, ">clust_size.tsv");
open(LOG, ">cluster.log");

$n_clusters = scalar(@order);
print LOG "Found $n_clusters\n";
print LOG "KEY:\n";
foreach $a (keys(%colors)) {
	print LOG "$a\t $colors{$a}\n";
}
print LOG "\n\n\n";
print LOG "-"x80;
print LOG "\nID\t #sturctures \t | secondary Structure \t | Frames\n";
print LOG "-"x80;
print LOG "\n";
for ($i = 0; $i < scalar(@order); $i++ ) {
	print LOG "$i \t $clust{$order[$i]} | $order[$i]\t  | $clust_frames{$order[$i]}\n";
	print HIST "$i\t$clust{$order[$i]}\n";
}




		
