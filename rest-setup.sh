#!/bin/bash


for i in {0..19}; do

	cd $i
	
	pdb2gmx -ff charmm27 -f snap_$i.gro -o snap_pre_box_$i.gro -p snap_$i.top -water tip3p -ignh &&

	editconf -bt cubic -f  snap_pre_box_$i.gro -o snap_box_$i.gro -box 12 12 12 &&

	genbox -cp snap_box_$i.gro -cs spc216.gro -o snap_wet_$i.gro -p snap_$i.top &&

	grompp -f test.mdp -c snap_wet_$i.gro &&

	genion -nn 2 -nname CL -p snap_$i.top -g ion.log -s snap_$i.top -o snap_ion_$i.gro  &&
	
	grompp -f test.mdp -c snap_wet_$i.gro || exit
	
	cd ..

done

