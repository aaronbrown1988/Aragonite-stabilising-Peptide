#!/bin/bash

#XTC=/media/EXTERNAL/brown/rest-feb/0/trajout.xtc 
#TPR=/media/EXTERNAL/brown/rest-feb/0/tpxout.tpr 
JSE=/home/brown/analysis/n16n_best.pdb

XTC=`echo $1`
TPR=`echo $2`


#cd ~/analysis/rest-feb/

DATE=`date +%y%m%d`

mkdir $DATE
rm current
ln -s $DATE current
cd $DATE

mkdir cluster
cd cluster

#for i in {'0.1','0.25','0.5','0.7'}; do
for i in {'0.25','0.4','0.5','0.6'}; do
	mkdir $i;
	cd $i;

	echo -e "4\n1\n" |  g_cluster -f $XTC -s  $TPR -g cluster.log -clid clust-id.xvg -cl clusters.pdb -dt 10 -method gromos -cutoff $i -minstruct 1

	bash ~/src/utils/cluster_post.sh 
	~/src/utils/clust_criteria.pl clust-id.xvg
	~/src/utils/clust_time.pl clust-id.xvg
	cat cluster.log | awk '{print $1,$3}' | sed -e 's/.*|//g' | sort -n | uniq | grep -P '^[0-9].*' >> clust_size.tsv
	#N=`grep Found cluster.log | awk '{print $2}'`
	N=`grep 'Number of structures' cluster.log | sed -e 's/.* //'`
	cat clust_size.tsv | awk -v n=$N '{ weight = $2 / n; print $1, weight}' >> clust_weights.tsv
	~/src/utils/clust_hist.pl clust_size.tsv

	
	cd ..;
done

cd ..


mkdir ramas
cd ramas

for i in {1..40} ; do
j=$[$i-1]

k=$[$i*500]
l=$[$j*500]
 g_rama -f $XTC -s $TPR -o rama-$l -b $l -e $k -dt 10;

 cat rama-$l.xvg | sed -e 's/^[#@].*//' > rama-$l.lou;

lines=`cat rama-$l.lou | wc -l`
echo -e "$lines\n" | ~/src/utils/a.out rama-$l.lou
rm rama-$l.lou
cat ~/src/utils/head_rama density_plot > rama-color-$l.xvg
rm density_plot

 ~/src/utils/patchy_rama.pl rama-$l.xvg >> patchy_detail.tsv
 ~/src/utils/patchy_rama_corse.pl rama-$l.xvg >>patchy_coarse.tsv
done


g_rama -f $XTC -s $TPR -o rama-full -dt 10
 cat rama-full.xvg | sed -e 's/^[#@].*//' > tmp.lou;
lines=`cat tmp.lou | wc -l`
echo -e "$lines\n" | ~/src/utils/a.out tmp.lou
rm tmp.lou
cat ~/src/utils/head_rama density_plot > rama-color-full.xvg
rm density_plot

g_rama -f $XTC -s $TPR -o rama-0-10ns -dt 10 -b 0 -e 10000
 cat rama-0-10ns.xvg | sed -e 's/^[#@].*//' > tmp.lou;
lines=`cat tmp.lou | wc -l`
echo -e "$lines\n" | ~/src/utils/a.out tmp.lou
rm tmp.lou
cat ~/src/utils/head_rama density_plot > rama-color-0-10ns.xvg
rm density_plot

g_rama -f $XTC -s $TPR -o rama-10-20ns -dt 10 -b 10000 -e 20000
 cat rama-10-20ns.xvg | sed -e 's/^[#@].*//' > tmp.lou;
lines=`cat tmp.lou | wc -l`
echo -e "$lines\n" | ~/src/utils/a.out tmp.lou
rm tmp.lou
cat ~/src/utils/head_rama density_plot > rama-color-10-20ns.xvg
rm density_plot

g_rama -f $XTC -s $TPR -o rama-20-30ns -dt 10 -b 20000 -e 30000
 cat rama-20-30ns.xvg | sed -e 's/^[#@].*//' > tmp.lou;
lines=`cat tmp.lou | wc -l`
echo -e "$lines\n" | ~/src/utils/a.out tmp.lou
rm tmp.lou
cat ~/src/utils/head_rama density_plot > rama-color-20-30ns.xvg
rm density_plot


g_rama -f $XTC -s $TPR -o rama-30ns -dt 10 -b 30000
 cat rama-30ns.xvg | sed -e 's/^[#@].*//' > tmp.lou;
lines=`cat tmp.lou | wc -l`
echo -e "$lines\n" | ~/src/utils/a.out tmp.lou
rm tmp.lou
cat ~/src/utils/head_rama density_plot > rama-color-30ns.xvg
rm density_plot



cd ..

mkdir rmsd
cd rmsd

echo -e "4\n4\n" | g_rms -s $JSE -f $XTC -o traj_rmsd.xvg -dt 10 

cd ..




mkdir cam
cd cam
mkdir raw
cd raw
echo -e "1\n1\n" | trjconv -f $XTC -s $TPR -o .pdb -pbc whole  -center -sep -dt 10
#mok '{$MOL->write("$i.pdb", format=>"pdb"); $i++;}BEGIN {$i=0}' trajout.pdb 
for i in `ls *.pdb`; do
	sed -e 's/ [AB] /   /' $i > $i.new;
	mv $i.new $i;
	camshift --data ~/local/share/camshift/data --pdb $i > $i.camshift
done;
~/src/utils/cam_avg.pl `pwd` 30 > ../camshift.tsv
~/src/utils/cam_rmsd.pl ~/analysis/colino_HN_HA.tsv ./ > ../rmsd.log
cd ..

cd ..

mkdir hbond
cd hbond

#echo -e "1\n1\n" | g_hbond -f $XTC -s $TPR -dist hbdist.xvg -life hblife.xvg -ac hbac.xvg  -num hbnum.xvg -g hb.log 
perl ~/src/utils/hbonds.pl ../cam/raw > HB.xvg

cd ..



mkdir trj
cd trj
~/src/utils/charge_dist.pl ../cam/raw > charge_dist.dat
~/src/utils/ring_distances.pl ../cam/raw> ring_dist.dat
~/src/utils/ss_plot.pl ../cam/raw > ss.xvg
cd ..
