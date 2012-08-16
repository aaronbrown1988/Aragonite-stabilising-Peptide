
trjconv -f /media/EXTERNAL/brown/rest-feb/0/trajout.xtc -s /media/EXTERNAL/brown/rest-feb/0/tpxout.tpr -o ./trajout.pdb -pbc whole -dt 10
mok '{$MOL->write("$i.pdb", format=>"pdb"); $i++;}BEGIN {$i=0}' trajout.pdb 
rm trajout.pdb
for i in `ls *.pdb`; do
	camshift --data ~/local/share/camshift/data --pdb $i > $i.camshift
done;
~/src/utils/cam_avg.pl `pwd` 30 > camshift.tsv
~/src/utils/cam_rmsd.pl ~/analysis/colino_HN_HA.tsv > rmsd.log
mkdir raw
mv *.pdb.camshift raw/
	
