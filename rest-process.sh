#!/bin/bash

XTC=/media/EXTERNAL/brown/rest-feb/0/trajout.xtc 
TPR=/media/EXTERNAL/brown/rest-feb/0/tpxout.tpr 
JSE=/home/brown/analysis/n16n_best.pdb

cd ~/analysis/rest-feb/

DATE=`date +%y%m%d`

mkdir $DATE
cd $DATE

mkdir cluster
cd cluster

for i in {'0.1','0.25','0.5'}; do
	mkdir $i;
	cd $i;

	echo -e "4\n1\n" |  g_cluster -f $XTC -s  $TPR -g cluster.log -clid clust-id.xvg -cl clusters.pdb -dt 10 -method gromos -cutoff $i

	bash ~/src/utils/cluster_post.sh
	~/src/utils/clust_criteria.pl clust-id.xvg
	~/src/utils/clust_time.pl clust-id.xvg
	cat cluster.log | awk '{print $1,$3}' | sed -e 's/.*|//g' | sort -n | uniq | grep -P '^[0-9].*' >> clust_size.tsv
	N=`grep Found cluster.log | awk '{print $2}'`
	cat clust_size.tsv | awk -v n=$N '{ weight = $2 / n; print $1, weight}' >> clust_weights.tsv

	
	cd ..;
done

cd ..


mkdir ramas
cd ramas

for i in {1..48} ; do
j=$[$i-1]

k=$[$i*500]
l=$[$j*500]
 g_rama -f $XTC -s $TPR -o rama-$l -b $l -e $k -dt 10; 
 ~/src/utils/patchy_rama.pl rama-$l >> patchy_detail.tsv
 ~/src/utils/patchy_rama_corse.pl rama-$l >>patchy_coarse.tsv
done


cd ..

mkdir rmsd
cd rmsd

echo -e "4\n4\n" | g_rms -s $JSE -f $XTC -o traj_rmsd.xvg -dt 10 

cd ..


mkdir trj
cd trj

cat /media/EXTERNAL/brown/rest-feb/0/md.log /media/EXTERNAL/brown/rest-feb/0/md.part00*.log >> md.log

demux.pl md.log 

 
cd ..



