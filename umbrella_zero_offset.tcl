set cht [atomselect top "resname CHT"];
set pep [atomselect top "protein"];
set c1 [atomselect top "name C1 and x > 25"];

set a [measure center $c1];
set b [measure center $cht];
set c [measure center $pep];

set a [lindex $a 0];
set b [lindex $b 0];
set c [lindex $c 0];
expr (($c - $b)  - ($a - $b));
expr ($c - $a);
set off [expr ($a-$b)	];
puts "Offset: $off"
exit
