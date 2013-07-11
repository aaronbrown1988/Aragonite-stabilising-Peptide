#!/usr/bin/perl
use Chart::Gnuplot::Pie;
open(FH, "$ARGV[0]");

my $chart = Chart::Gnuplot::Pie->new(
	        output => "$ARGV[0]-pie.png",
	        title  => "$ARGV[1]"
		);

$n = 0;
while ($line = readline(FH)) {
	@params = split(/\s+/, $line);
	$data[$n][0] = "$params[0]";
	$data[$n][1] = $params[1];
	push(@colors, $params[2]);
	$n++;
}
if (@colors > 0) {
$dataSet = Chart::Gnuplot::Pie::DataSet->new( data=> \@data, colors => \@colors);
} else {
$dataSet = Chart::Gnuplot::Pie::DataSet->new( data=> \@data);

}

$chart->plot3d($dataSet);


