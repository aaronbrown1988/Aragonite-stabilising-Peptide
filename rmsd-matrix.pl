#!/usr/bin/perl


open (FH, $ARGV[0]) || die "$!";

while ($line = readline(FH)) {
if ($line =~ /^static.*/) {
	last;
}
}
$line = readline(FH);
$line =~ s/\"//g;
@params = split (/\s+/, $line);

$letters = $params[3];
$size = $params[0];
$colors = $params[2];
for ($i = 0; $i < $colors; $i++) {
	$line = readline(FH);
	$line =~ s/\"//g;
	@params = split (/\s+/, $line);
	$colors{$params[0]} = $params[4];
#	print "$params[0] = $params[4]\n";
}
$black = $params[0];
while ($line = readline(FH)) { 
	if ($line !~ /^\/\*.*/) {
		last;
	}
}
$line =~ s/\"//g;
push(@matrix, $line);
print "$matrix[0]";

for ($i = 1; $i < $size; $i++) {
	if (eof(FH)) {
		print "WHOA! We only got to $i...before we got to eof\n";
		die;
	}
	$line = readline(FH);
	$line =~ s/\"//g;
	push(@matrix, $line);
}

$dist = substr($matrix[$size-$ARGV[1] - 1], ($ARGV[2]*$letters),$letters);
$dist = $colors{$dist};

$inv_dist = substr ($matrix[$size-$ARGV[2] - 1],($letters*$ARGV[1]), $letters);
$inv_dist = $colors{$inv_dist};

print "We got $dist or $inv_dist for $ARGV[1] and $ARGV[2]\n";


for ($i = 0; $i <= $ARGV[1]; $i++) {
	$dist = substr($matrix[$size - $i - 1], ($letters*$ARGV[1]),$letters);
	if ($dist eq "$black") {
		push(@clust, $i);
	}
}
for ($i = $ARGV[1] ; $i < $size; $i++) {
	$dist = substr($matrix[$size - $ARGV[1] - 1], ($letters*$i) ,$letters);
	if ($dist eq "$black") {
		push(@clust, $i);
	}
}
$mem = scalar(@clust) +1 ;
print "$mem in cluster with $ARGV[1] : @clust\n";


# Lets fudge about doing our own clustering
$left = $size -1;

#while ($left != 0) {
	for ($i = 0; $i <$size; $i++) {
		$mine{$i} = 0;
		$my_neighbours{$i} = "";
		for ($j = 0; $j < $size; $j++) {
			if ($i == $j) {
				next;
			} elsif ($i > $j) {
				$dist = substr($matrix[$size-$i - 1], ($letters*$j),$letters);
			} elsif ($j > $i) {
				$dist = substr($matrix[$size-$j - 1], ($letters*$i),$letters);
			}
			if ($colors{$dist} <= $ARGV[3]) {
				$mine{$i}++;
				$my_neighbours{$i} = "$my_neighbours{$i} $j";
			}
		}
	}


 
@order = sort { $mine{$b} <=> $mine{$a}} keys(%mine);
print "Top 10 frames by neighbour:\n";
for ($i = 0; $i < 10; $i++) {
	print " $order[$i] \t$mine{$order[$i]}\n";
}

print " Asked for cluster got $mine{$ARGV[1]}\n";


print "Top frames neighbours: $my_neighbours{$order[0]}\n";
