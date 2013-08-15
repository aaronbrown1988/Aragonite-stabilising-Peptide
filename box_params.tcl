set n [molinfo 0 get numframes];
for {set i 0} {$i < $n} {incr i} {
	animate goto $i;
	set values [pbc get];
	echo $values;
}

exit
