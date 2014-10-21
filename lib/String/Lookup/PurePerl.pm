package String::Lookup::PurePerl;   # fake
package String::Lookup;

# version info
$VERSION= '0.03';

# make sure we're strict and verbose as possible
use strict;
use warnings;

# constants we need
use constant OFFSET    => 0;  # initial / current offset
use constant INCREMENT => 1;  # increment value between ID's
use constant THEHASH   => 2;  # hash ref with string -> id mapping
use constant THELIST   => 3;  # list ref with id -> string mapping
use constant INDEX     => 4;  # keys() index
use constant FLUSH     => 5;  # code to flush
use constant TODO      => 6;  # id's added
use constant AUTOFLUSH => 7;  # code 

# modules that we need
use Scalar::Util qw( reftype );

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
    my @errors;

    # create object
    my $self= bless [], $class;

    # overrides
    $self->[OFFSET]=    delete $param{offset}    || 0;
    $self->[INCREMENT]= delete $param{increment} || 1;

    # sanity check
    push @errors, "Offset may not be negative"    if $self->[OFFSET]    < 0;
    push @errors, "Increment may not be negative" if $self->[INCREMENT] < 0;

    # need to initialize the lookup hash
    if ( my $init= delete $param{init} ) {

        # fill the hash
        my $hash= $self->[THEHASH]= reftype($init) eq 'HASH'
          ? $init
          : $init->();

        # make sure the list is set up as well
        my @list;
        $list[ $hash->{$_} ]= $_ foreach keys %{$hash};
        $self->[OFFSET]=  $#list if $#list > $self->[OFFSET];
        $self->[THELIST]= \@list;
    }

    # start afresh
    else {
        $self->[THEHASH]= {};
        $self->[THELIST]= [];
    }

    # do we flush?
    $self->[FLUSH]= delete $param{flush} if exists $param{flush};
    if ( my $autoflush= delete $param{autoflush} ) {

        # huh?
        if ( !$self->[FLUSH] ) {
            push @errors, "Doesn't make sense to autoflush without flush";
        }

        # autoflushing by seconds
        elsif ( $autoflush =~ m#^([0-9]+)s$# ) {
            my $seconds= $1;
            my $epoch=   time + $seconds;
            $self->[AUTOFLUSH]= sub {
                $epoch += $seconds, shift->flush if time >= $epoch;
            };
        }

        # autoflushing by number of new ID's
        elsif ( $autoflush =~ m#^[0-9]+$# ) {
            $self->[AUTOFLUSH]= sub {
                $_[0]->flush if @{ $_[0]->[TODO] } == $autoflush;
            };
        }

        # huh?
        else {
            push @errors, "Don't know what to do with autoflush '$autoflush'";
        }
    }

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

            # store string and index
            my $index= $self->[OFFSET] += $self->[INCREMENT];
            $self->[THEHASH]->{ 
              $self->[THELIST]->[$index]= ${ $_[0] } # premature optimization
            }= $index;

            # flushing
            return $index if !$self->[FLUSH];
            push @{ $self->[TODO] }, $index;

            # autoflushing
            return $index if !$self->[AUTOFLUSH];
            $self->[AUTOFLUSH]->($self);

            return $index;
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
    my $self= shift;

    # initializations
    my $index= $self->[INDEX]= 0;
    my $list=  $self->[THELIST];

    # find the next
    $list->[$index] and $self->[INDEX]= $index and return $list->[$index]
      while ++$index < @{$list};

    # alas
    return undef;
} #FIRSTKEY

#-------------------------------------------------------------------------------
# NEXTKEY
#
#  IN: 1 underlying object
# OUT: 1 next key

sub NEXTKEY {
    my $self= shift;

    # initializations
    my $index= $self->[INDEX];
    my $list=  $self->[THELIST];

    # find the next
    $list->[$index] and $self->[INDEX]= $index and return $list->[$index]
      while ++$index < @{$list};

    # alas
    return undef;
} #NEXTKEY

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
# OUT: 1 return value from flush sub

sub flush {
    my $self= shift;

    # nothing to do
    my $flush= $self->[FLUSH] or return;
    my $todo=  $self->[TODO]  or return;

    # perform the flush
    undef $self->[TODO]
      if my $return= $flush->( $self->[THELIST], $todo );

    return $return;
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
