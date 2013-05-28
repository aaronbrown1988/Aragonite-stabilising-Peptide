#!/bin/bash
#
# Compare the centroid cluster structures to each other from different simu
# simulations
#

if [ $# != 2 ]; then
	echo "USAGE: FolderA FolderB";
	echo "where A and B contian pdbs";
	exit
fi
A=`echo $1`
B=`echo $2`
rm rmsd.tsv
touch rmsd.tsv
echo "#$A $B RMSD" >> rmsd.tsv  
for i in `ls $A/*.pdb`;  do
	 iname=`echo $i | sed -e 's/.pdb.*//; s/.*\///g;'`
	 if [ $iname == "clusters" ]; then
	 	continue;
	fi
#	if [ $iname -gt 10 ]; then
#		continue;
#	fi
	 for j in `ls $B/*.pdb`; do
	 	jname=`echo $j | sed -e 's/.pdb.*//; s/.*\///g;'`
	 	if [ $jname == "clusters" ]; then
	 		continue;
		fi
#		if [ $jname -gt 10 ]; then
#			continue;
#		fi
#	 	echo "#iname:$iname jname:$jname from $i and $j" >> rmsd.tsv
	 	echo -e "4\n4\n" | g_rms -s "$i" -f "$j";
#	 	echo "-1" > rmsd.xvg
		cat rmsd.xvg | sed -e "s/-1/$iname $jname/" > rmsd.xvg2
		rm rmsd.xvg
		cat rmsd.xvg2 | grep -e '^[^@#].*' >> rmsd.tsv;
		rm rmsd.xvg2
	done
	echo "" >> rmsd.tsv
done


