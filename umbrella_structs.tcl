set all [ atomselect top "all" ]
set inp "0"
set curr "0"
while {$inp != -1} {
	animate goto $inp
	$all writepdb $curr.pdb
	set curr [ expr ($curr + 1)]
	set inp [gets stdin]
}
