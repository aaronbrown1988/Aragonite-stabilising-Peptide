package LAMMPS::BondType;

use strict;
use warnings;

our $VERSION="0.01";

sub new{
	my ($class, %args) = @_;
	my $self = bless ({
		type => "",
		kb => "",
		b0 => "" , $class);
		
	return $self;
}

sub set {
	my $self = shift;
	my  %args = @_;

	$self->{type} = defined $args{type} ? $args{type}: $self->{type};
	$self->{kb} = defined $args{kb} ? $args{kb}: $self->{kb};
	$self->{b0} = defined $args{b0} ? $args{b0}: $self->{b0};
	
}

sub to_string {
	my $self = shift;
	my $out;
	$out = "\t$self->{kb}\t$self->{b0}\t#$self->type\n";
	return $out;
}
1;
