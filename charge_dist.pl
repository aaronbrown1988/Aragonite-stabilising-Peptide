#!/usr/bin/perl
use POSIX;
use Chemistry::Mol;
use Chemistry::File::PDB;

my @neg;
my @pos;

#Args dir_with_pdbs output;
opendir(DH, $ARGV[0]) || die "couldn't open $ARGV[0]: $!\n";

while ($file = readdir(DH)) {
        if ($file !~ /.*pdb/) {
                next;
        }
        $mol = Chemistry::MOl->read($file);
        if (@neg < 1 ) {
                #find atoms were after atoms 
                @atoms = $mol->atoms;
                for ($i=0; $i < @atoms; $i++) {
                        $at = $mol->by_id($atoms[$i]);
                        if ($at->name() eq 'CA' && ($at->res() eq 'ASP' || $at->res eq 'GLU')) {
                        push(@neg, $atoms[$i]);
                        }
                        if ($at->name() eq 'CA' && ($at->res() eq 'ARG' || $at->res eq 'LYS')) {
                        push(@pos, $atoms[$i]);
                        }
                }
        }
        for($i = 0; $i < @neg ; $i++) {
                for ($j = 0; $j < @pos; $j++ ) {
                        $at = $mol->by_id($atoms[$i]);
                        $at2 = $mol->by_id($atoms[$j]);
                        @coords = $at->coord();
			@coords2 = $at2->coord();
			$dist = ($coords[0] - $coords2[0])**2;
			$dist += ($coords[0] - $coords2[0])**2;
			$dist += ($coords[0] - $coords2[0])**2;
			$dist = sqrt($dist);
			$id = $i * @pos + $j;
			$dists[$id] = $dist;
		}
	}
	print "$file\t@dists\n";
}
