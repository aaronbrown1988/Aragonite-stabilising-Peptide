package LAMMPS::AtomType;

use strict;
use warnings;

our $VERSION="0.01";

sub new{
	my ($class, %args) = @_;
	my $self = bless ({
		mass => "",
		type => "",
		eps => "",
		sig => "",
		eps14 => "",
		sig14 =>""}, $class);
		
	return $self;
}

sub print {
	my $self = shift;
	print "mass $self->{mass}\n";
	print "type $self->{type}\n";
	print "eps $self->{eps}\n";
	print "sig $self->{sig}\n";
	print "eps14 $self->{eps14}\n";
	#print "sig14 $self->{sig14}\n";
	
}

sub set {
	my $self = shift;
	my  %args = @_;

	$self->{mass} =  defined $args{mass} ? $args{mass}: $self->{mass};
	$self->{type} = defined $args{type} ? $args{type}: $self->{type};
	$self->{eps} = defined $args{eps} ? $args{eps}: $self->{eps};
	$self->{sig} = defined $args{sig} ? $args{sig}: $self->{sig};
	$self->{eps14} = defined $args{eps14} ? $args{eps14}: $self->{eps14};
	$self->{sig14} = defined $args{sig} ? $args{sig14}: $self->{sig};
}

1;
		
		
