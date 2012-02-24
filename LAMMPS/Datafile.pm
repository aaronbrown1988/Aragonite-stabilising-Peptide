package LAMMPS::Datafile;

use LAMMPS::AtomType;

#use strict;
use warnings;

our $VERSION="0.01";

=head1 NAME
 LAMMPS::Datafile - My object for huffing lammps data around
 
=cut

sub new {
	my ($class, %args) = @_;
	my $self = bless ({
		atoms => [],
		bonds => [],
		angles => [],
		dihedrals => [],
		impropers => [],
		
		box_dim => [],
		
		masses => [],
		charges => [],
		
		dihedraltypes => [],
		bondtypes => [],
		angletypes => [],
		atomtypes => [],
		impropertypes => []}, $class);
		
		return $self;
}


sub add_atom {
	my $self = shift;
	for my $atom (@_) {
		push @{$self->{atoms}}, $atom;
	}
}

sub list_atoms {
	my $self = shift;
	for my $atom (@{$self->{atoms}}) {
		print "$atom\n";
	}
}


sub add_bond {
	my $self = shift;
	for my $bond (@_) {
		push @{$self->{bonds}}, $bond;
	}
}

sub add_dihedral {
	my $self = shift;
	for my $dih (@_) {
		push @{$self->{dihedral}}, $dih;
	}
}

sub add_angle {
	my $self = shift;
	for my $ang (@_) {
		push @{$self->{angles}}, $ang;
	}
}


sub read_data {
	my $self = shift;
	my $line;
	open(FH, $_[0]) || die "Couldn't open $_[0]";
	$line = readline(FH);
	
	while ($line = readline(FH)) {
		if ($line =~ /.*Masses.*/) {
			last;
		}
	}
	$line = readline(FH);
	while ($line = readline(FH)) {
		if (length($line) < 3 ) {
			last;
		} else {
			my ($throw, $id, $mass, $type) = split (/\s+/, $line);
			push @{$self->{masses}}, $mass;
			my $atom = new LAMMPS::AtomType();
			$atom->{mass} = $mass;
			$atom->set(type => $type);
			push @{$self->{atomtypes}}, $atom;
		}
	}
	
	
	while ($line = readline(FH)) {
		if ($line =~ /.*Pair Coeffs.*/) {
			last;
		}
	}
	$line = readline(FH);
	while ($line = readline(FH)) {
		if (length($line) < 3 ) {
			last;
		} else {
			my ($throw, $id, $eps, $sig, $eps14, $sig14) = split (/\s+/, $line);
			$id--;
			${$self->{atomtypes}}[$id]->set(eps => $eps, sig => $sig, eps14 => $eps14, sig14=> $sig14);
		}
	}

	close(FH);
	
}
	
	
sub write {
	my $self = shift;
	for my $atom (@{$self->{atomtypes}}) {
		$atom->print;
	}
}
	
		
1;

