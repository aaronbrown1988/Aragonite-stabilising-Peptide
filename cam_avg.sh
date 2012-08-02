
trjconv -f /media/EXTERNAL/brown/rest-feb/0/trajout.xtc -s /media/EXTERNAL/brown/rest-feb/0/tpxout.tpr -o ./trajout.pdb
mok '{$MOL->write("$i.pdb", format=>"pdb"); $i++;}BEGIN {$i=0}' trajout.pdb 
rm trajout.pdb
for i in `ls *.pdb`; do
	camshift --data ~/local/share/camshift/data --pdb $i > $i.camshift
done;
~/src/utils/cam_avg.pl `pwd` 30 > camshift.tsv
	
