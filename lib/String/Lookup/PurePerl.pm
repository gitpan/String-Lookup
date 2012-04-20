package String::Lookup::PurePerl;   # fake
package String::Lookup;

# version info
$VERSION= '0.01';

# make sure we're strict and verbose as possible
use strict;
use warnings;

# constants we need
use constant OFFSET    => 0;
use constant INCREMENT => 1;
use constant THEHASH   => 2;
use constant THELIST   => 3;
use constant FLUSH     => 4;
use constant TODO      => 5;

# synonyms 
do {
    no warnings 'once';
    *DESTROY= \&flush;
    *UNTIE=   \&flush;
};

# actions we cannot do on a lookup hash
sub CLEAR  { die "Cannot clear a lookup hash"               } #CLEAR
sub DELETE { die "Cannot delete strings from a lookup hash" } #DELETE
sub STORE  { die "Cannot assign values to a lookup hash"    } #STORE

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl functionality
#
#-------------------------------------------------------------------------------
# TIEHASH
#
#  IN: 1 class
#      2 .. N parameters
# OUT: 1 blessed object

sub TIEHASH {
    my ( $class, %param )= @_;

    # create object
    my $self= bless [], $class;

    # overrides
    $self->[OFFSET]=    delete $param{offset}    || 0;
    $self->[INCREMENT]= delete $param{increment} || 1;

    # need to initialize the lookup hash
    if ( my $init= delete $param{init} ) {

        # fill the hash
        my $hash= $self->[THEHASH]= $init->();

        # make sure the list is set up as well
        my @list;
        $list[ $hash->{$_} ]= $_ foreach keys %{$hash};
        $self->[OFFSET]=  $#list;
        $self->[THELIST]= \@list;
    }

    # start afresh
    else {
        $self->[THEHASH]= {};
        $self->[THELIST]= [];
    }

    # do we flush?
    $self->[FLUSH]= delete $param{flush} if exists $param{flush};

    my @errors;
    # huh?
    if ( my @huh= sort keys %param ) {
        push @errors, "Don't know what to do with: @huh";
    }

    # sorry
    die join "\n", "Found the following problems:", @errors if @errors;

    return $self;
} #TIEHASH

#-------------------------------------------------------------------------------
# FETCH
#
#  IN: 1 underlying object
#      2 key to fetch (id or ref to string)
# OUT: 1 id or string

sub FETCH {
    my $self= shift;

    # string lookup
    if ( ref $_[0] ) {
        return $self->[THEHASH]->{ ${ $_[0] } } || do {

            # need to add to the hash
            my $index= $self->[OFFSET] += $self->[INCREMENT];
            $self->[TODO] .= pack 'w', $index if $self->[FLUSH];
            $self->[THELIST]->[$index]= ${ $_[0] };
            return $self->[THEHASH]->{ ${ $_[0] } }= $index;
        };
    }

    # id lookup
    return $self->[THELIST]->[ $_[0] ];
} #FETCH

#-------------------------------------------------------------------------------
# EXISTS
#
#  IN: 1 underlying object
#      2 key to fetch (id or ref to string)
# OUT: 1 boolean

sub EXISTS {

    return ref $_[1]
      ? exists  $_[0]->[THEHASH]->{ ${ $_[1] } }   # string exists
      : defined $_[0]->[THELIST]->[    $_[1]   ];  # id exists
} #EXISTS

#-------------------------------------------------------------------------------
# FIRSTKEY
#
#  IN: 1 underlying object
# OUT: 1 first key

sub FIRSTKEY {

     # reset the keys on the underlying hash
     my $keys= keys %{ $_[0]->[THEHASH] };

     return each %{ $_[0]->[THEHASH] };
} #FIRSTKEY

#-------------------------------------------------------------------------------
# NEXTKEY
#
#  IN: 1 underlying object
# OUT: 1 next key

sub NEXTKEY { each %{ $_[0]->[THEHASH] } } #NEXTKEY

#-------------------------------------------------------------------------------
# SCALAR
#
#  IN: 1 underlying object
# OUT: 1 underlying hash (for fast lookups)

sub SCALAR { $_[0]->[THEHASH] } #SCALAR

#-------------------------------------------------------------------------------
#
# Instance Methods
#
#-------------------------------------------------------------------------------
# flush (and DESTROY and UNTIE)
#
#  IN: 1 underlying object

sub flush {
    my $self= shift;

    # nothing to do
    my $flush= $self->[FLUSH] or return;
    my $todo=  $self->[TODO]  or return;

    # perform the flush
    undef $self->[TODO]
      if $flush->( $self->[THELIST], [ unpack 'w*', $todo ] );

    return;
} #flush

#-------------------------------------------------------------------------------

__END__

=head1 NAME

String::Lookup::PurePerl - pure Perl implementation of String::Lookup

=head1 SYNOPSIS

 use String::Lookup;

 tie my %lookup, 'String::Lookup', ( parameters );

 my $id= $lookup{ \$string }; # strings must be indicated by reference
 my $string= $lookup{$id};    # numbers indicate id -> string mapping

=head1 DESCRIPTION

Please see the documentation in L<String::Lookup>.

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

Copyright (c) 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
