#!/bin/bash


for i in {0..15}; do
	mkdir $i
    cp -rf ./charmm27.ff $i/
	cd $i
	cp ../snap_$i.* ./
	cp ../test.mdp ./
	cp ../test.pbs ./
	echo -e "0\n3\n" | pdb2gmx -ff charmm27 -f snap_$i.* -o snap_pre_box_$i.gro -p snap.top -water tip3p -ignh -ter  || exit
	cd ..
done

#~/utils/rest-setup snap.top 16 300 500


for i in {0..1}; do

	cd $i


	editconf -bt cubic -f  snap_pre_box_$i.gro -o snap_box_$i.gro -box 12 12 12 &&

	genbox -cp snap_box_$i.gro -cs spc216.gro -o snap_wet_$i.gro -p snap.top -nmol 57512 -maxsol 57512 &&

	grompp -f test.mdp -c snap_wet_$i.gro -p snap.top -maxwarn 2&&
	echo -e "13\n" | genion -nn 3 -nname CL -p snap.top -g ion.log  -o snap_ion_$i.gro || exit 

	gmxdump -s topol.tpr > gmxdump.log;
	
	../tiff.pl gmxdump.log snap.top 300 500 0
	mv snap.top.tiff snap.top

	../rest-setup snap.top $i 15 300 500 || exit 
	~/src/utils/cmap.pl ./charmm27.ff/cmap.itp 300 500
##	exit
	mv snap.top.new snap.top
	mv charmm27.ff/ffbonded.itp.new charmm27.ff/ffbonded.itp
	mv charmm27.ff/ffnonbonded.itp.new charmm27.ff/ffnonbonded.itp
	
	
#	grompp -f test.mdp -c snap_ion_$i.gro -p snap.top -maxwarn 4 -v -pp || exit
	
	cd ..
done

