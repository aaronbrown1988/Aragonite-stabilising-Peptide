#!/bin/bash
XTC=$1
TPR=$2
CUTOFF=$3
steps=`gmxcheck -f $XTC 2>&1 | grep Step | awk '{print $2};'`
time=$[$steps*10 - 10]
end=10000;
while [[ $end -le $time ]]; do
	name=$[$end/1000];
	name=$name"ns"
	echo -e "4\n1\n" | g_cluster -f $XTC -s $TPR -method gromos -e $end -o $name-rmsd-clust.xpm -g $name.log -dist $name-dist.xvg -clid $name-id.xvg -cutoff $CUTOFF -cl $name.pdb 2>&1 > $name-my.log
	n=`fgrep Found $name.log | awk ' {print $2};'`
	echo "$end $n" >> clust_time.tsv
	end=$[$end+10000];
done

