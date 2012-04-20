package String::Lookup;

# version info
$VERSION= '0.01';

# make sure we're strict and verbose as possible
use strict;
use warnings;

# just use the PurePerl implementation for now
use String::Lookup::PurePerl;

# satisfy -require-
1;

#-------------------------------------------------------------------------------

__END__

=head1 NAME

String::Lookup - convert strings to ID's authoritatively and vice-versa

=head1 SYNOPSIS

 use String::Lookup;

 tie my %lookup, 'String::Lookup',
   init  => sub { },  # code to initialize hash with
   flush => sub { },  # code to flush hash with
 };

 my $id= $lookup{ \$string }; # strings must be indicated by reference
 my $string= $lookup{$id};    # numbers indicat id -> string mapping

 # optimizing by bypassing the slow tie interface
 my $ro_lookup= %lookup;
 my $id= $ro_lookup->{$string} // $lookup{ \$string };

=head1 VERSION

This documentation describes version 0.01.

=head1 DESCRIPTION

Provide a simple way to map (a great number of) strings to ID's authoritatively.
Uses the C<tie> interface for simplicity.  Looking up the ID of a string is
accomplished by B<passing a reference to the string> as the key in the tied
hash.  If a reference is seen, it is assumed this is a string -> ID lookup
(even if the string only consists of a number).  If a non-reference is passed,
then it is assumed to be the numeric ID for which the string should be returned.

=head1 INITIALIZATION

 tie my %lookup, 'String::Lookup',
   init  => sub { return $hash_ref },  # code to initialize hash with
 };

The C<init> parameter indicates a code reference that will be called to
initialize the lookup hash.  The subroutine is supposed to return a hash
reference that should be used as the underlying hash in which string to
numerical ID mapping is stored.

A simple implementation, that assumes strings will never contain newlines,
could be:

 sub simple_init {
     my %hash;
     open my $handle, '<', 'file.lookup' or die $!;
     while ( <$handle> ) {
         my ( $id, $string )= split ':', $_, 2;
         $hash{$id}= $string;
     }
     close $handle;
     return \%hash;
 } #simple_init

=head1 FLUSHING

 tie my %lookup, 'String::Lookup',
   flush => sub { my ( $strings, $ids )= @_ },  # code to flush hash with
 };

The C<flush> parameter indicates a code reference that will be called to
save strings that have been added since the hash was created / initialized,
or the previous time the tied hash was flushed.  By default, the hash is only
flushed when being C<untie>d, or when the tied hash is destroyed.

It is supposed to accept two parameters:

=over 4

=item 1 list reference for id -> string mapping

The first parameter is a list reference to the underlying array that is used
for the ID to string mapping.

=item 2 list reference to ID's that were added

The second parameter is a list reference to the numeric ID's that were added
since the last flush (if any).

=back

A simple implementation, that assumes strings will never contain newlines,
could be:

 sub simple_flush {
     my ( $strings, $ids )= @_;
     open my $handle, '>>', 'file.lookup' or die $!;
     print $handle, "$_:$strings->[$_]\n" foreach @{$ids};
     close $handle;
 } #simple_flush

=head1 OPTIMIZING STRING LOOKUPS

 # optimizing by bypassing the slow tie interface if possible
 my $ro_lookup= %lookup;
 my $id= $ro_lookup->{$string} // $lookup{ \$string };

The C<tie> interface is notoriously slow.  If a high number of strings needs
to be looked up, then the lookups may slow things down a lot.  Since we only
want to lookup strings because they occur again and again, it makes sense to
not have to use the C<tie> interface if the string has already an ID assigned
to it.  But the underlying hash lookup is hidden by the C<tie> interface.
If it would be possible to access the underlying (real) hash, then that could
be used to first check if a string is already known.

Finding out what the underlying real hash is, is possible by accessing the
tied hash in scalar context once: it will then return a reference to the
underlying hash, allowing direct lookup access.  Like so:

 my $ro_lookup= %lookup;

If there is no defined value returned from the underlying hash, then the
original, tied hash access should be used to automatically obtain the numeric
ID.  Like so:

 my $id= $ro_lookup->{$string} // $lookup{ \$string };

Please note that the lookup in the underlying hash should be made with the
string, and the lookup in the tied hash with the B<reference to> the string!

=head1 BACKGROUND

At a former $client, a large amount of (similar) string data is processed
every second.  Think user agent strings, IPv4 and IPv6 numbers, URL's, tags and
labels, domain names, HTTP input headers, affiliate ID's, etc. etc.

To reduce the database I/O, all of these strings are converted to numeric ID's.
ID's can be smaller, and more easily packed than strings.  But if a database
is being used to assign numeric ID's (usually using an auto-increment feature),
this means overhead.  Overhead that is generally not needed for what is
basically either a hash lookup, or an index on an array.  This would be
different if we could have a daemon like process whose function it would only
be to assign numeric ID's to strings without needing a database backend.

This module provides the basic interface mechanism for such a daemon.

=head1 IMPLEMENTATION

At the moment there is only a pure Perl reference implementation available.
This has the disadvantage of being slower than it could possibly be made.  But
it works B<now>.  It is the intention of providing a faster XS interface at a
later point in time.

=head1 REQUIRED MODULES

 (none)

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

Copyright (c) 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
