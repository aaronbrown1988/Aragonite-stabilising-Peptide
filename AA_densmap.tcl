volmap density [atomselect top "protein"] -res 1 -weight mass -allframes -combine avg -mol top -o protein.dx 



mol new protein.dx
mol delrep 1 0
mol modstyle 0 1 {VolumeSlice 0.37 X High} 
mol modstyle 0 0 {DynamicBonds 1.8 0.6 10}
mol modselect 0 0 "resname CHT and not hydrogen"
mol modmaterial 0 1 "Translucent"
#mol modmaterial 0 1 "Transparent"
rotate z to 90
rotate y to 270
scale by 2.25
render TachyonInternal  test-dens.tga
exit
