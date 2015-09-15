#!/usr/bin/perl
#
# Surface interations.
#
# USAGE: surf_cont.pl FOLDER_OF_PDBS SURF_RES SURF_FACE
#
# Caveat: Doesn't care about PBCS, assumes +ve direction is away from slab
use threads;
use threads::shared;
use POSIX;
local $|=1;
my $surf_res :shared;
$surf_res = $ARGV[1];
my $surf_dir :shared;
$surf_dir = $ARGV[2];
my $file;
my $path :shared;
$path = $ARGV[0];
my @files :shared;
my %sites :shared;
my @contacts :shared;
my @dists :shared;
my @threads;
my @hist :shared;
my @second :shared;

%sites = (
		ALA => 'CB',
		ARG => 'CZ',
		ASN => 'ND2',
		ASP => 'CG',
		GLN => 'N',
		GLU => 'CD',
		GLY => 'CA',
		CYS => 'SG',
		HIS => 'COM',
		ILE => 'CD',
		LEU => 'CD',
		LYS => 'NZ',
		MET => 'S',
		PRO => 'CG',
		PHE => 'COM',
		SER => 'OG',
		THR => 'O',
		TRP => 'COM',
		TYR => 'OH',
		VAL => 'CB'
		);



opendir(DH, "$ARGV[0]") || die "Couldn't open $ARGV[0]:$!\n";

while ($file = readdir(DH)) {
	if ($file =~ /.*\.pdb\b/) {
		push(@files, $file);
	}
}
closedir(DH);

for ($i = 0; $i < 70; $i++) {
	$second[$i] = 0;
}

for ($j = 0; $j < 4; $j ++) {
	$hist[$j] = (shared_clone(\@second));
}




#spawn out threads
for ($i=0; $i < 4; $i++) {
	$threads[$i] = threads->create('run_me');
}
# attach threads to main process - this sets them running, 
# and importantly makes this process wait.
for ($i=0; $i < 4; $i++) {
	$threads[$i]->join();
}




sub run_me {
	my $id = threads->tid();
	$progress = "1/5000";
	for ($fid = $id-1; $fid < scalar(@files); $fid+=4) {
#	for ($fid = $id-1; $fid < 4; $fid+=4) {
		process($files[$fid]);
		print "\b" x (length($progress) + 1);
		$nfiles = scalar(@files);
		$progress = "$fid/$nfiles";
		print  "$progress";
	}
}



#
# Aggregate Histograms together
#
for ($i = 0; $i < 70; $i++) {
	$hist[0][$i] += $hist[1][$i];
	$hist[0][$i] += $hist[2][$i];
	$hist[0][$i] += $hist[3][$i];
}

open(HIST, ">hist.tsv");
for ($i = 0; $i < 70; $i++) {
	print HIST "$i\t$hist[0][$i]\n";
}
close(HIST);


open(CONT, ">contact.tsv") || die "couldn't open contact.tsv for writing\n" ;
open(DISTS, ">resid_dist.tsv") || die "couldn't open resid_dist.tsv for writing\n" ;
for ($i = 0; $i < scalar(@dists); $i++) {
	print DISTS "$dists[$i]";
}
for ($i = 0; $i < scalar(@contacts); $i++) {
	print CONT "$contacts[$i]";
}
close(CONT);
close(DISTS);



sub process {
#my @surf;
#	my @atoms;
	my $cont = "";
	my $ncont =0;
	my $outline = "";
	my $res_start;
	my $min_heavy;
	$cur_file = @_[0];
	open(FH, "$path/$cur_file") || die "Couldn't open $ARGV[0]/$cur_file :$!\n";
	while ($line = readline(FH)) {
		if ($line =~ /^ATOM.*/) {
			if ($line =~ /.*$surf_res.*/) {
				push(@surf, $line);
			} elsif ($line !~ /.*SOL.*/) {
				push(@atoms, $line);
			}
		}
	}
	close(FH);

	#Find the top of the surface
	$surf_max = -9.9e99;
	foreach $line (@surf) {
		@params = split(/\s+/, $line);
		if ($params[4] =~ /[A-Z]+/) {
			$surf_max = ($params[6+$surf_dir] > $surf_max)?$params[6+$surf_dir]:$surf_max;
		} else {
			$surf_max = ($params[5+$surf_dir] > $surf_max)?$params[5+$surf_dir]:$surf_max;
		}
	}
#	print STDERR "$cur_file\tTop:$surf_max \n";
	#Convert this to an average over the top layer
	my $top_layer = 0;
	my $n = 0;

	# Find the base of the troughs on alpha-chitin
	foreach $line (@surf) {
		@params = split(/\s+/, $line);
		if ($params[4] =~ /[A-Z]+/) {
			if ($params[6+$surf_dir] > ($surf_max-10)) {
				$top_layer += $params[6+$surf_dir];
				$n++;
			}
		} else {
			if ($params[5+$surf_dir] > ($surf_max-10)) {
				$top_layer += $params[5+$surf_dir];
				$n++;
			}
		}
	}
	$top_layer /= $n;
	$file_res = 0;
	$cur_res = 0;
	$cur_file =~ s/[A-Za-z]//g;
	$cur_file =~ s/\.//;
	$outline =  "$cur_file\t$top_layer";

	#Loop over atoms
	for ($i = 0; $i < scalar(@atoms); $i++) {
		@params = split(/\s+/, $atoms[$i]);
		if ($params[4] != $file_res) {
			$cur_res++;
			$file_res = $params[4];
			$res_start = $i;
		} else {
			next;
		}
		if ($sites{$params[3]} eq "COM") {
			$com = 0;
			$ncom = 0;
		#	print STDERR "FOUND RING $params[3] starting at $i: @params\n";
			while($params[4] == $file_res) {
				if ($params[2] =~ /C.*/) {
					$com += $params[5+$surf_dir];
					$ncom++;
				}
				$i++;
			#	print STDERR "COMLine $i\n";
				@params = split(/\s+/,$atoms[$i]);
			}
			$i--;
			@params = split(/\s+/,$atoms[$i]);
			#print STDERR "$cur_res is $params[3] built COM upto line $i\n";
			$com = $com/$ncom;
			$dist = $com - $top_layer;
	
		} elsif ($sites{$params[3]} eq undef) {
			# Skip Unknown residues/ residues without defined sites
			next;
		} else {
			while($params[2] ne $sites{$params[3]}) {
			#	print STDERR "Search: $cur_res Line $i: @params != $sites{$params[3]}\n";
				$i++;
				@params = split(/\s+/, $atoms[$i]);
				if ($params[4] != $file_res) {
					print "@params $file_res\n";
					$i--;
					last;
				}
			}
			if ($params[2] ne $sites{$params[3]}) {
				die "$cur_res $params[2] ne $sites{$params[3]}";
			} else {
			#	print STDERR " FOUND $cur_res on $i  $params[2] = $sites{$params[3]}\n";
			}
			$dist = $params[5+$surf_dir] - $top_layer;
			
		}
		$outline=  "$outline\t$dist";
		if ($dist <= 6 ) {
			$ncont++;
			$cont = "$cont,$params[3]$params[4]";
		} elsif ($dist <= 11) {
			$min_heavy = 9e99;
			$k = 0;
			foreach $line (@surf) {
				$k++;
				@params = split(/\s+/, $line);
				$col_slab = ($params[4] =~ /[A-Z]+/)? 6:5;
				@at_params = split(/\s+/, $atoms[$res_start]);
				$j = 0;
				while ($at_params[4] == $file_res) {
					$dist = ($at_params[5] - $params[$col_slab])**2;
					$dist += ($at_params[6] - $params[$col_slab+1])**2;
					$dist += ($at_params[7] - $params[$col_slab+2])**2;
					$dist = ($dist**0.5);
					
					$min_heavy = ($min_heavy > $dist)? $dist:$min_heavy;
					$j ++;
					@at_params = split(/\s+/, $atoms[$res_start+$j]);

				}
			}
			if ($min_heavy == 9e99) {
				die "COuldn't calulate min chitin distance: $res_start, $j,$k, $file_res, $at_params[4], $dist\n";
			}
			$min_heavy = floor($min_heavy);
			$hist[$id][$min_heavy]++;
		
		}


	}
	$outline= "$outline\n";
	# Added calculated data to the output buffers
	{lock @dists; push(@dists,$outline);}
	{lock @contacts;  push(@contacts, "$cur_file\t$ncont\t$cont\n");}
	#close file
	close(FH);
	#Free some ram
	undef(@surf);
	undef(@atoms);
}

