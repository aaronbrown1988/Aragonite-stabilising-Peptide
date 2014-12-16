#
# Quick and dirty method to dump a phi psi pairs
# vmd your.psf your.dcd -e namd_rama.tcl
#
    set fp [ open "phi-psi.dat" w ] 
    set sel [ atomselect top "alpha" ] 
    set n [ molinfo top get numframes ] 
    for {set i 0 } { $i < $n } { incr i } { 
        $sel frame $i 
        $sel update 
        set a [ $sel num ] 
        for {set j 1 } { $j < ($a-1) } { incr j } { 
            puts $fp "[lindex [$sel get {phi psi}] $j]"
        } 
    } 
    $sel delete 
    close $fp
    exit
