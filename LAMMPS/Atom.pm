package LAMMPS::Atom;

use strict;
use warnings;

our $VERSION="0.01";

sub new{
	my ($class, %args) = @_;
	my $self = bless ({
		type => "",
		coords => [],
		charge => ""}, $class);
		
	return $self;
}


sub set{
	my $self = shift;
	my %args = @_;
	$self->{type} = exists $args{type}? $args{type} : $self->{type};
	$self->{charge} = exists $args{charge}? $args{charge} : $self->{charge};
	$self->{coords} = (exists $args{coords})? split(/,/,$args{coords}) : $self->{coords};
}
1;
		
		
