#!/bin/bash


clusters=`mok '{println $i; $i++;}BEGIN {$i=0}' clusters.pdb | tail -n 1`

#Extract all clusters
mok '{$MOL->write("$i.pdb", format=>"pdb"); $i++;}BEGIN {$i=0}' clusters.pdb

#Throw everything after top 4

i=11;
while [ $i -lt $clusters ]
do
	rm $i.pdb;
	let "i = $i +1"
done

#rm {11..$[$clusters]}.pdb

#rm rmsd.tsv
#touch rmsd.tsv
rm shift_rmsd.tsv
rm coupl_rmsd.tsv

for i in {0..10};
do
	stride $i.pdb > $i.stride;
	camshift --data ~/local/share/camshift/data --pdb $i.pdb > $i.camshift
	~/src/utils/shift-comp.pl $i.camshift ../nmr_shifts.csv >> shift_rmsd.tsv
	g_chi -s $i.pdb -f $i.pdb -g $i.gchi
	rm order.xvg
	~/src/utils/coupl-rmsd.pl $i.gchi.log ../../coupl/nmr.dat >> coupl_rmsd.tsv
	let j=$i
#	while [ "$j" -lt "4" ]
#	do
	#	rm rmsd.xvg
	#	echo -e "4\n4\n" | g_rms -s $i -f $j;
	#	sed -i -e "s/-1/$i\t$j/" rmsd.xvg
	#	cat rmsd.xvg >> rmsd.tsv;
	#	let "j = $j +1"
#	done
done

