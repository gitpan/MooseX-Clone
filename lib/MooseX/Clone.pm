#!/usr/bin/perl

package MooseX::Clone;
use Moose::Role;

our $VERSION = "0.01";

use Hash::Util::FieldHash::Compat qw(idhash);

use MooseX::Clone::Meta::Attribute::Trait::Clone;

sub clone {
    my ( $self, %params ) = @_;

    my $meta = $self->meta;

    my @cloning;

    idhash my %clone_args;

    attr: foreach my $attr ($meta->compute_all_applicable_attributes()) {
        # collect all attrs that can be cloned.
        # if they have args in %params then those are passed to the recursive cloning op
        if ( $attr->does("MooseX::Clone::Meta::Attribute::Trait::Clone") ) {
            push @cloning, $attr;

            if ( defined( my $init_arg = $attr->init_arg ) ) {
                if ( exists $params{$init_arg} ) {
                    $clone_args{$attr} = delete $params{$init_arg};
                }
            }
        }
    }

    my $clone = $meta->clone_object($self, %params);

    foreach my $attr ( @cloning ) {
        $clone->clone_attribute(
            proto => $self,
            attr => $attr,
            ( exists $clone_args{$attr} ? ( init_arg => $clone_args{$attr} ) : () ),
        );
    }

    return $clone;
}

sub clone_attribute {
    my ( $self, %args ) = @_;

    my ( $proto, $attr ) = @args{qw/proto attr/};

    $attr->clone_value( $self, $proto, %args );
}

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Clone - Fine grained cloning support for L<Moose> objects.

=head1 SYNOPSIS

    package Bar;
    use Moose;

	with qw(MooseX::Clone);

    has foo => (
        isa => "Foo",
        traits => [qw(Clone)], # this attribute will be recursively cloned
    );

    package Foo;
    use Moose;

    # this API is used/provided by MooseX::Clone
    sub clone {
        my ( $self, %params ) = @_;

        # ...
    }


    # used like this:

    my $bar = Bar->new( foo => Foo->new );

    my $copy = $bar->clone( foo => [ qw(Args for Foo::clone) ] );

=head1 DESCRIPTION

Out of the box L<Moose> only provides very barebones cloning support in order
to maximize flexibility.

This role provides a C<clone> method that makes use of the low level cloning
support already in L<Moose> and adds selective deep cloning based on
introspection on top of that. Attributes marked for 

=head1 METHODS

=over 4

=item clone %params

Returns a clone of the object.

All attributes which do the L<MooseX::Clone::Meta::Attribute::Trait::Clone>
role will handle cloning of that attribute. All other fields are plainly copied
over, just like in L<Class::MOP::Class/clone_object>.

Attributes whose C<init_arg> is in %params and who do the C<Clone> trait will
get that argument passed to the C<clone> method (dereferenced). If the
attribute does not self-clone then the param is used normally by
L<Class::MOP::Class/clone_object>, that is it will simply shadow the previous
value, and does not have to be an array or hash reference.

=back

=head1 TODO

Refactor to work in term of a metaclass trait so that C<<meta->clone_object>>
will still do the right thing.

=head1 THANKS

clkao made the food required to write this module

=head1 VERSION CONTROL

L<http://code2.0beta.co.uk/moose/svn/>. Ask on #moose for commit bits.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
